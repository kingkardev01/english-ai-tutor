import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/message.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/progress/data/firestore_progress_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Correction correction(String s, {bool mistake = true, int score = 6}) =>
    Correction(
      original: s,
      hasMistake: mistake,
      corrected: '$s (fixed)',
      explanation: 'Because.',
      score: score,
    );

void main() {
  final now = DateTime(2026, 10, 30, 10);
  late FakeFirebaseFirestore db;
  late FirestoreProgressRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreProgressRepository(db, 'uid-1', clock: () => now);
  });

  test('stores everything under users/{uid}', () async {
    final sessionId = await repo.startSession(
      const TutorSettings(level: Level.beginner, topic: Topic.jobInterview),
    );
    await repo.saveMessage(sessionId, MessageRole.user, 'Hello');
    await repo.recordCorrection(
      sessionId,
      correction('I has a job', score: 4),
      topic: Topic.jobInterview,
    );
    await repo.recordCorrection(
      sessionId,
      correction('I like it', mistake: false, score: 10),
      topic: Topic.jobInterview,
    );

    final user = (await db.doc('users/uid-1').get()).data()!;
    expect(user['level'], 'beginner');
    expect(user['streakDays'], 1);
    expect(user['totalScore'], 14);
    expect(user['sentencesChecked'], 2);

    final session = (await db.doc('users/uid-1/sessions/$sessionId').get())
        .data()!;
    expect(session['topic'], 'jobInterview');
    expect(session['messageCount'], 1);
    expect(session['avgScore'], 7.0);

    final messages = await db
        .collection('users/uid-1/sessions/$sessionId/messages')
        .get();
    expect(messages.docs.single.data()['role'], 'user');

    final mistakes = await db.collection('users/uid-1/mistakes').get();
    expect(mistakes.docs.single.data()['original'], 'I has a job');
  });

  test('watchProgress and watchMistakes map the stored data', () async {
    await repo.recordCorrection('s', correction('a'), topic: Topic.travel);

    // Snapshot streams can start with an older cached value, so wait until
    // they reach the expected one.
    await expectLater(
      repo.watchProgress().map((p) => p.sentencesChecked),
      emitsThrough(1),
    );

    final mistake = await repo.watchMistakes().firstWhere(
      (list) => list.isNotEmpty,
    );
    expect(mistake.single.original, 'a');
    expect(mistake.single.topic, 'Travel');
    expect(mistake.single.createdAt, now);

    await repo.setReviewed(mistake.single.id, reviewed: true);
    await expectLater(
      repo.watchMistakes().map((list) => list.single.reviewed),
      emitsThrough(isTrue),
    );
  });
}
