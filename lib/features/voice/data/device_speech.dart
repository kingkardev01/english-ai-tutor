import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../domain/voice_services.dart';

class DeviceSpeechInput implements SpeechInput {
  final _speech = SpeechToText();
  Future<bool>? _initialized;
  void Function()? _onDone;

  @override
  Future<bool> initialize() => _initialized ??= _speech.initialize(
    onStatus: (status) {
      if (status == SpeechToText.doneStatus ||
          status == SpeechToText.notListeningStatus) {
        _finish();
      }
    },
    onError: (_) => _finish(),
  );

  @override
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    _onDone = onDone;
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: 'en_US',
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  /// The plugin reports the end of listening more than once; call [_onDone]
  /// only the first time.
  void _finish() {
    final done = _onDone;
    _onDone = null;
    done?.call();
  }
}

class DeviceSpeechOutput implements SpeechOutput {
  final _tts = FlutterTts();
  late final Future<void> _ready = _setUp();

  Future<void> _setUp() async {
    await _tts.setLanguage('en-US');
    // A little slower than normal, so learners can follow.
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> speak(String text) async {
    await _ready;
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
