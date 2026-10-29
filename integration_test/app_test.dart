import 'package:english_ai_tutor/app/app.dart';
import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_tutor_repository.dart';
import '../test/helpers/test_overrides.dart';

/// Runs the whole app on a device or simulator with the AI and storage
/// faked, so it needs no keys:
///
///     flutter test integration_test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pick a topic → send a message → reply, correction, history', (
    tester,
  ) async {
    final tutor = FakeTutorRepository()
      ..correctionFor = (s) => Correction(
        original: s,
        hasMistake: true,
        corrected: 'I went to the market yesterday.',
        explanation: 'Use the past tense "went".',
        score: 6,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(tutor: tutor),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // Home → Daily life
    await tester.tap(find.byKey(const Key('topic_dailyLife')));
    await tester.pumpAndSettle();
    expect(find.text('Daily life · Intermediate'), findsOneWidget);

    // Send a sentence with a mistake
    await tester.enterText(
      find.byKey(const Key('chat_input')),
      'I go to the market yesterday.',
    );
    await tester.tap(find.byKey(const Key('send_button')));
    await tester.pump();

    // The reply streams in, and the correction card appears
    tutor.emit('That sounds fun! ');
    await tester.pump();
    tutor.emit('What did you buy?');
    await tutor.finish();
    await tester.pumpAndSettle();

    expect(find.text('That sounds fun! What did you buy?'), findsOneWidget);
    expect(find.byKey(const Key('correction_card')), findsOneWidget);
    expect(find.text('I went to the market yesterday.'), findsOneWidget);

    // Back home → the chat is in history
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history_button')));
    await tester.pumpAndSettle();
    expect(find.text('I go to the market yesterday.'), findsOneWidget);
  });
}
