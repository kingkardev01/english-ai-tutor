import 'package:cloud_firestore/cloud_firestore.dart';

import '../../chat/domain/correction.dart';
import '../../chat/domain/message.dart';
import '../../chat/domain/tutor_settings.dart';
import '../domain/mistake.dart';
import '../domain/progress.dart';
import '../domain/progress_repository.dart';

/// Stores everything under `users/{uid}`, so one security rule covers it:
///
///     users/{uid}                  level, streakDays, lastPracticeDate,
///                                  totalScore, sentencesChecked
///       sessions/{sessionId}       topic, level, startedAt, messageCount,
///                                  avgScore
///         messages/{messageId}     role, text, createdAt
///       mistakes/{mistakeId}       original, corrected, explanation,
///                                  topic, createdAt, reviewed
class FirestoreProgressRepository implements ProgressRepository {
  FirestoreProgressRepository(this._db, this._uid, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _mistakeLimit = 200;

  final FirebaseFirestore _db;
  final String _uid;
  final DateTime Function() _clock;

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(_uid);
  CollectionReference<Map<String, dynamic>> get _sessions =>
      _user.collection('sessions');
  CollectionReference<Map<String, dynamic>> get _mistakes =>
      _user.collection('mistakes');

  @override
  Stream<Progress> watchProgress() =>
      _user.snapshots().map((s) => Progress.fromJson(s.data() ?? {}));

  @override
  Stream<List<Mistake>> watchMistakes() => _mistakes
      .orderBy('createdAt', descending: true)
      .limit(_mistakeLimit)
      .snapshots()
      .map((q) => q.docs.map(_mistakeFrom).toList());

  @override
  Future<String> startSession(TutorSettings settings) async {
    final session = _sessions.doc();
    await (_db.batch()
          ..set(_user, {'level': settings.level.name}, SetOptions(merge: true))
          ..set(session, {
            'topic': settings.topic.name,
            'level': settings.level.name,
            'startedAt': FieldValue.serverTimestamp(),
            'messageCount': 0,
            'avgScore': null,
          }))
        .commit();
    return session.id;
  }

  @override
  Future<void> saveMessage(String sessionId, MessageRole role, String text) {
    final session = _sessions.doc(sessionId);
    return (_db.batch()
          ..set(session.collection('messages').doc(), {
            'role': role.name,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..update(session, {'messageCount': FieldValue.increment(1)}))
        .commit();
  }

  /// One transaction updates the streak, the session average and the
  /// mistake list together, so they never disagree.
  @override
  Future<void> recordCorrection(
    String sessionId,
    Correction correction, {
    required Topic topic,
  }) {
    final session = _sessions.doc(sessionId);
    return _db.runTransaction((tx) async {
      final userSnap = await tx.get(_user);
      final sessionSnap = await tx.get(session);

      final progress = Progress.fromJson(
        userSnap.data() ?? {},
      ).record(correction.score, _clock());
      final s = sessionSnap.data() ?? {};
      final scoreTotal = (s['scoreTotal'] as num? ?? 0) + correction.score;
      final checked = (s['checkedCount'] as num? ?? 0) + 1;

      // Update existing docs so their other fields (like level) are kept.
      void write(DocumentSnapshot snap, Map<String, dynamic> data) =>
          snap.exists
          ? tx.update(snap.reference, data)
          : tx.set(snap.reference, data);

      write(userSnap, progress.toJson());
      write(sessionSnap, {
        'scoreTotal': scoreTotal,
        'checkedCount': checked,
        'avgScore': scoreTotal / checked,
      });
      if (correction.hasMistake) {
        tx.set(_mistakes.doc(), {
          'original': correction.original,
          'corrected': correction.corrected,
          'explanation': correction.explanation,
          'topic': topic.label,
          'createdAt': Timestamp.fromDate(_clock()),
          'reviewed': false,
        });
      }
    });
  }

  @override
  Future<void> setReviewed(String mistakeId, {required bool reviewed}) =>
      _mistakes.doc(mistakeId).update({'reviewed': reviewed});

  static Mistake _mistakeFrom(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return Mistake(
      id: d.id,
      original: data['original'] as String? ?? '',
      corrected: data['corrected'] as String? ?? '',
      explanation: data['explanation'] as String? ?? '',
      topic: data['topic'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0),
      reviewed: data['reviewed'] as bool? ?? false,
    );
  }
}
