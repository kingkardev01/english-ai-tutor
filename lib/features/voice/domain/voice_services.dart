/// Speech-to-text, so the learner can speak instead of type.
abstract interface class SpeechInput {
  /// Asks for microphone permission on first use. Returns false when
  /// speech recognition is unavailable or permission is denied.
  Future<bool> initialize();

  /// Listens until the learner pauses. [onResult] receives the words heard
  /// so far, with `isFinal` true on the last call; [onDone] runs once when
  /// listening stops for any reason.
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    required void Function() onDone,
  });

  Future<void> stop();
}

/// Text-to-speech, so the tutor's replies can be heard.
abstract interface class SpeechOutput {
  /// Stops anything already playing, then speaks [text].
  Future<void> speak(String text);

  Future<void> stop();
}
