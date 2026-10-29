import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/constants/ai_constants.dart';
import '../domain/tutor_settings.dart';
import 'ai_service.dart';
import 'tutor_prompt.dart';

/// Gemini through Firebase AI Logic: no API key in the app, and App Check
/// protects the quota.
class FirebaseAiService implements AiService {
  FirebaseAiService(TutorSettings settings)
    : _chatModel = FirebaseAI.googleAI().generativeModel(
        model: kGeminiModel,
        systemInstruction: Content.system(tutorPrompt(settings)),
      ),
      _checker = FirebaseAI.googleAI().generativeModel(
        model: kGeminiModel,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: correctionSchema,
        ),
      );

  final GenerativeModel _chatModel;
  final GenerativeModel _checker;
  late final ChatSession _chat = _chatModel.startChat();

  @override
  Stream<String> reply(String message) => _chat
      .sendMessageStream(Content.text(message))
      .map((chunk) => chunk.text ?? '');

  @override
  Future<String?> checkGrammar(String sentence) async {
    final res = await _checker.generateContent([
      Content.text(grammarCheckPrompt(sentence)),
    ]);
    return res.text;
  }
}

/// Shared by both backends so the JSON shape is defined once.
final correctionSchema = Schema.object(
  properties: {
    'hasMistake': Schema.boolean(),
    'corrected': Schema.string(),
    'explanation': Schema.string(),
    'score': Schema.integer(description: '0-10, where 10 is perfect'),
  },
);
