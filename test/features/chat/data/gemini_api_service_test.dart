import 'dart:convert';

import 'package:english_ai_tutor/features/chat/data/gemini_api_service.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String sseChunk(String text) =>
    'data: ${jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    })}\n\n';

void main() {
  final requests = <http.Request>[];

  GeminiApiService serviceWith(
    Future<http.Response> Function(http.Request) handler,
  ) {
    requests.clear();
    return GeminiApiService(
      const TutorSettings(),
      apiKey: 'test-key',
      client: MockClient((req) {
        requests.add(req);
        return handler(req);
      }),
    );
  }

  test('streams SSE chunks and sends the key in a header', () async {
    final service = serviceWith(
      (_) async => http.Response(sseChunk('Hello ') + sseChunk('there!'), 200),
    );

    expect(await service.reply('Hi').toList(), ['Hello ', 'there!']);

    final req = requests.single;
    expect(req.url.path, endsWith(':streamGenerateContent'));
    expect(req.headers['x-goog-api-key'], 'test-key');
    expect(req.url.queryParameters.containsKey('key'), isFalse);
  });

  test('keeps chat history between turns', () async {
    final service = serviceWith(
      (_) async => http.Response(sseChunk('Reply'), 200),
    );

    await service.reply('First').toList();
    await service.reply('Second').toList();

    final contents = jsonDecode(requests.last.body)['contents'] as List;
    expect(contents.map((c) => c['role']), ['user', 'model', 'user']);
    expect(contents.last['parts'][0]['text'], 'Second');
  });

  test('a blocked reply yields nothing and is not added to history', () async {
    final service = serviceWith(
      (_) async => http.Response('data: {"promptFeedback":{}}\n\n', 200),
    );

    expect(await service.reply('First').toList(), isEmpty);
    await service.reply('Second').toList();

    final contents = jsonDecode(requests.last.body)['contents'] as List;
    expect(contents, hasLength(1));
  });

  test('throws GeminiApiException with the status code on errors', () {
    final service = serviceWith(
      (_) async => http.Response('{"error":"quota"}', 429),
    );

    expect(
      service.reply('Hi').toList(),
      throwsA(
        isA<GeminiApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          429,
        ),
      ),
    );
  });

  test('checkGrammar asks for JSON with the correction schema', () async {
    const json =
        '{"hasMistake":false,"corrected":"Hi","explanation":"","score":10}';
    final service = serviceWith(
      (_) async => http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': json},
                ],
              },
            },
          ],
        }),
        200,
      ),
    );

    expect(await service.checkGrammar('Hi'), json);

    final config = jsonDecode(requests.single.body)['generationConfig'];
    expect(config['responseMimeType'], 'application/json');
    expect(
      (config['responseSchema']['properties'] as Map).keys,
      containsAll(['hasMistake', 'corrected', 'explanation', 'score']),
    );
  });
}
