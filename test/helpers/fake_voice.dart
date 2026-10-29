import 'package:english_ai_tutor/features/voice/domain/voice_services.dart';

/// Tests call [hear] to simulate the learner speaking.
class FakeSpeechInput implements SpeechInput {
  FakeSpeechInput({this.available = true});

  final bool available;
  bool listening = false;
  void Function(String words, bool isFinal)? _onResult;
  void Function()? _onDone;

  @override
  Future<bool> initialize() async => available;

  @override
  Future<void> listen({
    required void Function(String words, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    listening = true;
    _onResult = onResult;
    _onDone = onDone;
  }

  @override
  Future<void> stop() async => _finish();

  void hear(String words, {bool isFinal = true}) {
    _onResult?.call(words, isFinal);
    if (isFinal) _finish();
  }

  void _finish() {
    listening = false;
    _onDone?.call();
    _onDone = null;
  }
}

class FakeSpeechOutput implements SpeechOutput {
  final spoken = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}
