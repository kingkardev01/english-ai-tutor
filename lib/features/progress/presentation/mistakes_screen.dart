import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_providers.dart';
import '../domain/mistake.dart';

/// Past mistakes to revise. Marking one as learned moves it out of the
/// "To review" list.
class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(mistakesProvider).value ?? const <Mistake>[];
    final shown = _showAll ? all : all.where((m) => !m.reviewed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mistake review')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('To review')),
                ButtonSegment(value: true, label: Text('All')),
              ],
              selected: {_showAll},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _showAll = s.single),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      all.isEmpty
                          ? 'No mistakes yet. Keep practising!'
                          : 'All mistakes reviewed. Great work!',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: shown.length,
                    itemBuilder: (_, i) => _MistakeCard(
                      key: ValueKey(shown[i].id),
                      mistake: shown[i],
                      onReviewed: (reviewed) => ref
                          .read(progressRepositoryProvider)
                          .setReviewed(shown[i].id, reviewed: reviewed),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({
    super.key,
    required this.mistake,
    required this.onReviewed,
  });

  final Mistake mistake;
  final ValueChanged<bool> onReviewed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final meta = [?mistake.topic, _shortDate(mistake.createdAt)].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mistake.original,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mistake.corrected,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (mistake.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(mistake.explanation, style: theme.textTheme.bodySmall),
                  ],
                  if (mistake.banglaExplanation case final bangla?) ...[
                    const SizedBox(height: 2),
                    Text(bangla, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 6),
                  Text(meta, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            IconButton(
              tooltip: mistake.reviewed ? 'Mark to review' : 'Mark as learned',
              onPressed: () => onReviewed(!mistake.reviewed),
              icon: Icon(
                mistake.reviewed ? Icons.check_circle : Icons.circle_outlined,
                color: mistake.reviewed ? colors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = d.toLocal();
  return '${local.day} ${months[local.month - 1]}';
}
