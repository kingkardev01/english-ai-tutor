import 'package:english_ai_tutor/features/progress/data/progress_providers.dart';
import 'package:english_ai_tutor/features/progress/domain/mistake.dart';
import 'package:english_ai_tutor/features/progress/domain/progress.dart';
import 'package:english_ai_tutor/features/progress/presentation/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_progress_repository.dart';

void main() {
  final mistakes = [
    Mistake(
      id: '1',
      original: 'She go home.',
      corrected: 'She goes home.',
      explanation: 'Add -es with she.',
      createdAt: DateTime(2026, 10, 29),
      topic: 'Daily life',
    ),
    Mistake(
      id: '2',
      original: 'I am agree.',
      corrected: 'I agree.',
      explanation: '',
      createdAt: DateTime(2026, 10, 28),
      reviewed: true,
    ),
  ];

  testWidgets('progress shows stats and opens the mistake review', (
    tester,
  ) async {
    final repo = FakeProgressRepository(
      progress: const Progress().record(4, DateTime.now()),
      mistakes: mistakes,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('4.0'), findsOneWidget); // average score
    expect(find.text('Mistakes to review'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review_mistakes_button')));
    await tester.pumpAndSettle();

    // "To review" hides the already-reviewed mistake.
    expect(find.text('She goes home.'), findsOneWidget);
    expect(find.text('I agree.'), findsNothing);
    expect(find.text('Daily life · 29 Oct'), findsOneWidget);

    await tester.tap(find.byTooltip('Mark as learned'));
    await tester.pumpAndSettle();
    expect(repo.mistakes.first.reviewed, isTrue);
    expect(find.text('All mistakes reviewed. Great work!'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('She goes home.'), findsOneWidget);
    expect(find.text('I agree.'), findsOneWidget);
  });
}
