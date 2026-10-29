import '../../chat/domain/correction.dart';
import '../../chat/domain/message.dart';
import '../../chat/domain/tutor_settings.dart';
import 'mistake.dart';
import 'progress.dart';

/// Saves practice sessions, scores, streaks and mistakes.
abstract interface class ProgressRepository {
  Stream<Progress> watchProgress();

  /// Newest first.
  Stream<List<Mistake>> watchMistakes();

  /// Starts a practice session and returns its id.
  Future<String> startSession(TutorSettings settings);

  Future<void> saveMessage(String sessionId, MessageRole role, String text);

  /// Adds the sentence score to progress and the streak, and saves the
  /// mistake when there is one.
  Future<void> recordCorrection(
    String sessionId,
    Correction correction, {
    required Topic topic,
  });

  Future<void> setReviewed(String mistakeId, {required bool reviewed});
}
