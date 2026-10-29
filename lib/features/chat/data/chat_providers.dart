import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/tutor_repository.dart';
import '../domain/tutor_settings.dart';
import 'ai_service.dart';
import 'chat_repository_impl.dart';
import 'firebase_ai_service.dart';
import 'gemini_api_service.dart';

/// Level and topic for the current session. Phase 2 adds a picker that
/// updates this; a new value starts a fresh Gemini chat session.
final tutorSettingsProvider = Provider<TutorSettings>(
  (ref) => const TutorSettings(),
);

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
