/// The two Gemini calls the tutor makes. Implemented once for Firebase AI
/// Logic and once for the Gemini API with a key, so the repository works
/// the same way with either backend.
abstract interface class AiService {
  /// Streams the tutor's reply chunk by chunk, keeping chat history.
  Stream<String> reply(String message);

  /// Returns the raw JSON text of a grammar check.
  Future<String?> checkGrammar(String sentence);
}
