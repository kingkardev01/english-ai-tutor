import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/progress/data/local_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late SharedPreferences prefs;

  LocalProgressRepository newRepo() =>
      LocalProgressRepository(prefs, clock: () => now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('records scores and saves only real mistakes', () async {
    final repo = newRepo();
    final session = await repo.startSession(const TutorSettings());

    await repo.recordCorrection(
      session,
      correction('I is ok'),
      topic: Topic.travel,
    );
    await repo.recordCorrection(
      session,
      correction('I am ok', mistake: false, score: 10),
      topic: Topic.travel,
    );

    final progress = await repo.watchProgress().first;
    expect(progress.sentencesChecked, 2);
    expect(progress.totalScore, 16);
    expect(progress.streakDays, 1);

    final mistakes = await repo.watchMistakes().first;
    expect(mistakes.single.original, 'I is ok');
    expect(mistakes.single.topic, 'Travel');
    expect(mistakes.single.reviewed, isFalse);
  });

  test('keeps data after the app restarts', () async {
    final repo = newRepo();
    await repo.recordCorrection('s', correction('a'), topic: Topic.travel);

    final restarted = newRepo();
    expect((await restarted.watchProgress().first).sentencesChecked, 1);
    expect(await restarted.watchMistakes().first, hasLength(1));
  });

  test('setReviewed updates the mistake and notifies watchers', () async {
    final repo = newRepo();
    await repo.recordCorrection('s', correction('a'), topic: Topic.travel);
    final id = (await repo.watchMistakes().first).single.id;

    final updates = repo.watchMistakes();
    final expectation = expectLater(
      updates.map((list) => list.single.reviewed),
      emitsInOrder([false, true]),
    );
    await pumpEventQueue();
    await repo.setReviewed(id, reviewed: true);
    await expectation;
  });
}
