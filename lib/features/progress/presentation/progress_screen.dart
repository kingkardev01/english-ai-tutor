import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_providers.dart';
import 'mistakes_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).value;
    final mistakes = ref.watch(mistakesProvider).value ?? const [];
    final toReview = mistakes.where((m) => !m.reviewed).length;
    final average = progress?.averageScore;

    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.extent(
            maxCrossAxisExtent: 240,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.4,
            children: [
              _StatTile(
                icon: Icons.local_fire_department,
                value: '${progress?.currentStreak(DateTime.now()) ?? 0}',
                label: 'Day streak',
              ),
              _StatTile(
                icon: Icons.star_outline,
                value: average == null ? '–' : average.toStringAsFixed(1),
                label: 'Average score /10',
              ),
              _StatTile(
                icon: Icons.chat_bubble_outline,
                value: '${progress?.sentencesChecked ?? 0}',
                label: 'Sentences practised',
              ),
              _StatTile(
                icon: Icons.spellcheck,
                value: '$toReview',
                label: 'Mistakes to review',
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('review_mistakes_button'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MistakesScreen())),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Review mistakes'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            Text(value, style: theme.textTheme.headlineMedium),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
