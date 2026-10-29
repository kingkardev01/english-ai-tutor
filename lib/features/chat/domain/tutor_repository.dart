import 'correction.dart';

/// Everything the chat screen needs from the AI tutor.
///
/// The presentation layer only knows this interface, so Gemini can be
/// swapped for another model, or a fake in tests, without touching the UI.
abstract interface class TutorRepository {
  /// Streams the tutor's reply chunk by chunk.
  ///
  /// Emits a fallback reply when the model returns nothing, and errors with
  /// a [TutorFailure] when the request fails.
  Stream<String> reply(String message);

  /// Checks [sentence] for grammar mistakes.
  ///
  /// Returns null when the check fails or returns bad JSON, so a missing
  /// correction never breaks the conversation.
  Future<Correction?> check(String sentence);
}
