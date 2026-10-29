import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/message.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/history/domain/chat_record.dart';
import 'package:english_ai_tutor/features/history/presentation/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_history_repository.dart';
import '../../../helpers/test_overrides.dart';

void main() {
  final chat = ChatRecord(
    id: 'c1',
    topic: Topic.jobInterview,
    level: Level.intermediate,
    startedAt: DateTime(2026, 10, 30, 14, 5),
    messages: const [
      Message(
        id: '0',
        role: MessageRole.user,
        text: 'I am work in a bank.',
        correction: Correction(
          original: 'I am work in a bank.',
          hasMistake: true,
          corrected: 'I work in a bank.',
          explanation: 'Remove "am".',
          score: 6,
        ),
      ),
      Message(id: '1', role: MessageRole.tutor, text: 'What do you do there?'),
    ],
  );

  Future<FakeHistoryRepository> pumpHistory(WidgetTester tester) async {
    final history = FakeHistoryRepository([chat]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(history: history),
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pump();
    return history;
  }

  testWidgets('lists past chats and opens one with its corrections', (
    tester,
  ) async {
    await pumpHistory(tester);

    expect(find.text('I am work in a bank.'), findsOneWidget);
    expect(
      find.text('Job interview · Intermediate · 30 Oct, 14:05'),
      findsOneWidget,
    );

    await tester.tap(find.text('I am work in a bank.'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryDetailScreen), findsOneWidget);
    expect(find.text('I work in a bank.'), findsOneWidget);
    expect(find.text('What do you do there?'), findsOneWidget);
  });

  testWidgets('swipe deletes a chat', (tester) async {
    final history = await pumpHistory(tester);

    await tester.drag(find.text('I am work in a bank.'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(history.chats, isEmpty);
    expect(find.text('Your past chats will appear here.'), findsOneWidget);
  });

  testWidgets('delete all asks first', (tester) async {
    final history = await pumpHistory(tester);

    await tester.tap(find.byTooltip('Delete all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(history.chats, hasLength(1));

    await tester.tap(find.byTooltip('Delete all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(history.chats, isEmpty);
  });
}
