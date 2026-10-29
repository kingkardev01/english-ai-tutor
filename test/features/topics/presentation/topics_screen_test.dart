import 'package:english_ai_tutor/features/chat/data/chat_providers.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/chat/presentation/chat_screen.dart';
import 'package:english_ai_tutor/features/progress/domain/progress.dart';
import 'package:english_ai_tutor/features/topics/presentation/topics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/test_overrides.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpTopics(WidgetTester tester, {Progress? progress}) {
    container = ProviderContainer(
      overrides: testOverrides(
        progress: FakeProgressRepository(
          progress: progress ?? const Progress(),
        ),
      ),
    );
    addTearDown(container.dispose);
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TopicsScreen()),
      ),
    );
  }

  testWidgets('shows the current streak', (tester) async {
    final today = DateTime.now();
    await pumpTopics(
      tester,
      progress: const Progress().record(8, today).record(6, today),
    );
    await tester.pump();

    expect(find.text('1-day streak'), findsOneWidget);
    expect(find.text('Average score 7.0/10'), findsOneWidget);
  });

  testWidgets('level and topic choice open the chat with those settings', (
    tester,
  ) async {
    await pumpTopics(tester);

    await tester.tap(find.text('Advanced'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topic_ieltsSpeaking')));
    await tester.pumpAndSettle();

    final settings = container.read(tutorSettingsProvider);
    expect(settings.level, Level.advanced);
    expect(settings.topic, Topic.ieltsSpeaking);
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('IELTS speaking · Advanced'), findsOneWidget);
  });

  testWidgets('the Bangla switch updates the settings', (tester) async {
    await pumpTopics(tester);

    await tester.tap(find.byKey(const Key('bangla_switch')));
    await tester.pump();

    expect(container.read(tutorSettingsProvider).explainInBangla, isTrue);
  });
}
