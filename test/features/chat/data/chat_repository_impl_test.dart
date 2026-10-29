import 'dart:async';
import 'dart:io';

import 'package:english_ai_tutor/core/constants/ai_constants.dart';
import 'package:english_ai_tutor/core/errors/tutor_failure.dart';
import 'package:english_ai_tutor/features/chat/data/chat_repository_impl.dart';
import 'package:english_ai_tutor/features/chat/data/ai_service.dart';
import 'package:english_ai_tutor/features/chat/data/gemini_api_service.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiService extends Mock implements AiService {}

void main() {
  late MockAiService ai;
  late ChatRepositoryImpl repo;

  setUp(() {
    ai = MockAiService();
    repo = ChatRepositoryImpl(ai);
  });

  group('reply', () {
    test('passes chunks through and drops empty ones', () async {
      when(
        () => ai.reply(any()),
      ).thenAnswer((_) => Stream.fromIterable(['Hi ', '', 'there!']));

      expect(await repo.reply('hello').toList(), ['Hi ', 'there!']);
    });

    test('emits the fallback reply when the model says nothing', () async {
      when(
        () => ai.reply(any()),
      ).thenAnswer((_) => Stream.fromIterable(['', '']));

      expect(await repo.reply('hello').toList(), [kFallbackReply]);
    });

    test('emits the fallback reply when the response is blocked', () async {
      when(() => ai.reply(any())).thenAnswer(
        (_) => Stream.error(FirebaseAIException('Response was blocked')),
      );

      expect(await repo.reply('hello').toList(), [kFallbackReply]);
    });

    test('maps quota errors to TutorBusyFailure', () {
      when(
        () => ai.reply(any()),
      ).thenAnswer((_) => Stream.error(QuotaExceeded('quota')));

      expect(repo.reply('hello'), emitsError(isA<TutorBusyFailure>()));
    });

    test('maps a Gemini API 429 to TutorBusyFailure', () {
      when(() => ai.reply(any())).thenAnswer(
        (_) => Stream.error(const GeminiApiException(429, 'Too many requests')),
      );

      expect(repo.reply('hello'), emitsError(isA<TutorBusyFailure>()));
    });

    test('maps network errors to NoConnectionFailure', () {
      when(() => ai.reply(any())).thenAnswer(
        (_) => Stream.error(const SocketException('Failed host lookup')),
      );

      expect(repo.reply('hello'), emitsError(isA<NoConnectionFailure>()));
    });
  });

  group('check', () {
    test('parses valid JSON into a Correction', () async {
      when(() => ai.checkGrammar(any())).thenAnswer(
        (_) async =>
            '{"hasMistake":true,"corrected":"She is happy.",'
            '"explanation":"Use is with she.","score":7}',
      );

      final c = await repo.check('She are happy.');

      expect(c, isNotNull);
      expect(c!.original, 'She are happy.');
      expect(c.corrected, 'She is happy.');
      expect(c.score, 7);
    });

    test('returns null on bad JSON instead of throwing', () async {
      when(() => ai.checkGrammar(any())).thenAnswer((_) async => 'not json');

      expect(await repo.check('x'), isNull);
    });

    test('returns null when the call fails', () async {
      when(() => ai.checkGrammar(any())).thenThrow(QuotaExceeded('quota'));

      expect(await repo.check('x'), isNull);
    });
  });

  group('mapAiError', () {
    test('recognises busy and offline errors from their text', () {
      expect(
        mapAiError(Exception('429 RESOURCE_EXHAUSTED')),
        isA<TutorBusyFailure>(),
      );
      expect(
        mapAiError(Exception('ClientException: Connection closed')),
        isA<NoConnectionFailure>(),
      );
      expect(mapAiError(TimeoutException('slow')), isA<NoConnectionFailure>());
      expect(mapAiError(StateError('boom')), isA<UnknownFailure>());
    });
  });
}
