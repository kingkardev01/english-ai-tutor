import 'package:english_ai_tutor/features/chat/data/chat_providers.dart';
import 'package:english_ai_tutor/features/history/data/history_providers.dart';
import 'package:english_ai_tutor/features/progress/data/progress_providers.dart';
import 'package:english_ai_tutor/features/voice/data/voice_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fake_history_repository.dart';
import 'fake_progress_repository.dart';
import 'fake_tutor_repository.dart';
import 'fake_voice.dart';

/// Replaces every outside dependency (AI, storage, microphone, speaker)
/// with a fake. Pass a fake to inspect it; the rest get fresh defaults.
List<Override> testOverrides({
  FakeTutorRepository? tutor,
  FakeProgressRepository? progress,
  FakeHistoryRepository? history,
  FakeSpeechInput? speechInput,
  FakeSpeechOutput? speechOutput,
}) => [
  tutorRepositoryProvider.overrideWithValue(tutor ?? FakeTutorRepository()),
  progressRepositoryProvider.overrideWithValue(
    progress ?? FakeProgressRepository(),
  ),
  historyRepositoryProvider.overrideWithValue(
    history ?? FakeHistoryRepository(),
  ),
  speechInputProvider.overrideWithValue(speechInput ?? FakeSpeechInput()),
  speechOutputProvider.overrideWithValue(speechOutput ?? FakeSpeechOutput()),
];
