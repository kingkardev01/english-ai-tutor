import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/tutor_repository.dart';
import '../domain/tutor_settings.dart';
import 'ai_service.dart';
import 'chat_repository_impl.dart';
import 'firebase_ai_service.dart';
import 'gemini_api_service.dart';

/// Level and topic for the current session. Every change, even to the same
/// values, starts a fresh Gemini chat session.
final tutorSettingsProvider =
    NotifierProvider<TutorSettingsNotifier, TutorSettings>(
      TutorSettingsNotifier.new,
    );

class TutorSettingsNotifier extends Notifier<TutorSettings> {
  @override
  TutorSettings build() => const TutorSettings();

  void setLevel(Level level) => state = state.copyWith(level: level);

  void setExplainInBangla(bool value) =>
      state = state.copyWith(explainInBangla: value);

  /// Starts a new practice session on [topic].
  void startTopic(Topic topic) => state = state.copyWith(topic: topic);
}

/// Uses the Gemini API key from config.json when there is one, otherwise
/// Firebase AI Logic.
final aiServiceProvider = Provider<AiService>((ref) {
  final settings = ref.watch(tutorSettingsProvider);
  return AppConfig.hasGeminiKey
      ? GeminiApiService(settings, apiKey: AppConfig.geminiApiKey)
      : FirebaseAiService(settings);
});

/// Override this in tests with a fake repository.
final tutorRepositoryProvider = Provider<TutorRepository>(
  (ref) => ChatRepositoryImpl(ref.watch(aiServiceProvider)),
);
