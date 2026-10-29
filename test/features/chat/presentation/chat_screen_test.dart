import 'package:english_ai_tutor/core/errors/tutor_failure.dart';
import 'package:english_ai_tutor/features/chat/data/chat_providers.dart';
import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/presentation/chat_screen.dart';
import 'package:english_ai_tutor/features/progress/data/progress_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/fake_tutor_repository.dart';

void main() {
  late FakeTutorRepository repo;

  Future<void> pumpChat(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        tutorRepositoryProvider.overrideWithValue(repo),
        progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
      ],
      child: const MaterialApp(home: ChatScreen()),
    ),
  );

  Future<void> sendText(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('chat_input')), text);
    await tester.tap(find.byKey(const Key('send_button')));
    await tester.pump();
  }

  setUp(() => repo = FakeTutorRepository());

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
}
