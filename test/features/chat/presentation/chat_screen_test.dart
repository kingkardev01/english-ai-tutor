import 'package:english_ai_tutor/core/errors/tutor_failure.dart';
import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/presentation/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_tutor_repository.dart';
import '../../../helpers/fake_voice.dart';
import '../../../helpers/test_overrides.dart';

void main() {
  late FakeTutorRepository repo;
  late FakeSpeechInput speechIn;
  late FakeSpeechOutput speechOut;

  Future<void> pumpChat(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        tutor: repo,
        speechInput: speechIn,
        speechOutput: speechOut,
      ),
      child: const MaterialApp(home: ChatScreen()),
    ),
  );

  Future<void> sendText(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('chat_input')), text);
    await tester.tap(find.byKey(const Key('send_button')));
    await tester.pump();
  }

  setUp(() {
    repo = FakeTutorRepository();
    speechIn = FakeSpeechInput();
    speechOut = FakeSpeechOutput();
  });

  testWidgets('shows streaming text and the correction card', (tester) async {
    repo.correctionFor = (s) => Correction(
      original: s,
      hasMistake: true,
      corrected: 'She goes to work.',
      explanation: 'Add -es with she.',
      score: 7,
    );
    await pumpChat(tester);
    expect(find.text('Say hello to start practising'), findsOneWidget);

    await sendText(tester, 'She go to work.');
    expect(find.text('She go to work.'), findsNWidgets(2)); // bubble + card
    expect(find.byKey(const Key('correction_card')), findsOneWidget);
    expect(find.text('She goes to work.'), findsOneWidget);

    repo.emit('Nice! ');
    await tester.pump();
    expect(find.text('Nice! '), findsOneWidget);

    repo.emit('Where do you work?');
    await repo.finish();
    await tester.pump();
    expect(find.text('Nice! Where do you work?'), findsOneWidget);
  });

  testWidgets('shows a friendly error with a working retry button', (
    tester,
  ) async {
    await pumpChat(tester);

    await sendText(tester, 'Hello');
    repo.fail(const TutorBusyFailure());
    await tester.pump();

    expect(find.text(const TutorBusyFailure().message), findsOneWidget);
    expect(find.text('Not sent'), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry_button')));
    await tester.pump();

    expect(repo.sentMessages, ['Hello', 'Hello']);
    expect(find.text(const TutorBusyFailure().message), findsNothing);
  });

  group('voice', () {
    Future<void> finishReply(WidgetTester tester, String text) async {
      repo.emit(text);
      await repo.finish();
      await tester.pump();
    }

    testWidgets('mic fills the text box without sending', (tester) async {
      await pumpChat(tester);

      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();
      speechIn.hear('I like tea');
      await tester.pump();

      expect(find.widgetWithText(TextField, 'I like tea'), findsOneWidget);
      expect(repo.sentMessages, isEmpty);
    });

    testWidgets('voice mode sends speech and reads the reply aloud', (
      tester,
    ) async {
      await pumpChat(tester);
      await tester.tap(find.byKey(const Key('voice_mode_button')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();
      speechIn.hear('I like tea', isFinal: false);
      await tester.pump();
      expect(repo.sentMessages, isEmpty);

      speechIn.hear('I like tea a lot');
      await tester.pump();
      expect(repo.sentMessages, ['I like tea a lot']);

      await finishReply(tester, 'Me too! Do you like coffee?');
      expect(speechOut.spoken, ['Me too! Do you like coffee?']);
    });

    testWidgets('replies are not read aloud when voice mode is off', (
      tester,
    ) async {
      await pumpChat(tester);
      await sendText(tester, 'Hello');
      await finishReply(tester, 'Hi!');

      expect(speechOut.spoken, isEmpty);

      await tester.tap(find.byTooltip('Listen'));
      expect(speechOut.spoken, ['Hi!']);
    });

    testWidgets('shows a message when the microphone is unavailable', (
      tester,
    ) async {
      speechIn = FakeSpeechInput(available: false);
      await pumpChat(tester);

      await tester.tap(find.byKey(const Key('mic_button')));
      await tester.pump();

      expect(find.textContaining('not available'), findsOneWidget);
    });
  });
}
