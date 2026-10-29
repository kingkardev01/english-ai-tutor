import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/ai_constants.dart';
import '../domain/tutor_settings.dart';
import 'ai_service.dart';
import 'firebase_ai_service.dart';
import 'tutor_prompt.dart';

/// Gemini through its REST API with the user's own API key.
///
/// Handy for running the demo without Firebase. The key ships inside the
/// app binary, so don't publish a build made with it.
class GeminiApiService implements AiService {
  GeminiApiService(
    TutorSettings settings, {
    required this._apiKey,
    http.Client? client,
  }) : _systemPrompt = tutorPrompt(settings),
       _client = client ?? http.Client();

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$kGeminiModel';

  final String _systemPrompt;
  final String _apiKey;
  final http.Client _client;
  final _history = <Map<String, Object>>[];

  @override
  Stream<String> reply(String message) async* {
    final userTurn = _turn('user', message);
    final request =
        http.Request(
            'POST',
            Uri.parse('$_baseUrl:streamGenerateContent?alt=sse'),
          )
          ..headers.addAll(_headers)
          ..body = jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': _systemPrompt},
              ],
            },
            'contents': [..._history, userTurn],
          });

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw GeminiApiException(
        response.statusCode,
        await response.stream.bytesToString(),
      );
    }

    final reply = StringBuffer();
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final text = _textOf(jsonDecode(line.substring(5)));
      if (text.isEmpty) continue;
      reply.write(text);
      yield text;
    }

    // Only finished turns join the history, like the Firebase ChatSession.
    if (reply.isNotEmpty) {
      _history
        ..add(userTurn)
        ..add(_turn('model', reply.toString()));
    }
  }

  @override
  Future<String?> checkGrammar(String sentence) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl:generateContent'),
      headers: _headers,
      body: jsonEncode({
        'contents': [_turn('user', grammarCheckPrompt(sentence))],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'responseSchema': correctionSchema.toJson(),
        },
      }),
    );
    if (response.statusCode != 200) {
      throw GeminiApiException(response.statusCode, response.body);
    }
    final text = _textOf(jsonDecode(response.body));
    return text.isEmpty ? null : text;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-goog-api-key': _apiKey,
  };

  static Map<String, Object> _turn(String role, String text) => {
    'role': role,
    'parts': [
      {'text': text},
    ],
  };

  /// Joins the text parts of the first candidate. A blocked or empty
  /// response has none and returns ''.
  static String _textOf(Object? json) {
    if (json case {
      'candidates': [{'content': {'parts': final List parts}}, ...],
    }) {
      return parts
          .map(
            (p) => p is Map && p['text'] is String ? p['text'] as String : '',
          )
          .join();
    }
    return '';
  }
}

class GeminiApiException implements Exception {
  const GeminiApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'GeminiApiException($statusCode): $body';
}
