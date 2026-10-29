import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/voice_services.dart';
import 'device_speech.dart';

/// Override these in tests with fakes.
final speechInputProvider = Provider<SpeechInput>((ref) => DeviceSpeechInput());

final speechOutputProvider = Provider<SpeechOutput>(
  (ref) => DeviceSpeechOutput(),
);

/// When on, a spoken message is sent as soon as the learner stops talking,
/// and the tutor's replies are read aloud.
final voiceModeProvider = NotifierProvider<VoiceModeNotifier, bool>(
  VoiceModeNotifier.new,
);

class VoiceModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
