import 'package:flutter/material.dart';

import '../../domain/correction.dart';

/// Shows a grammar check under the learner's message: the original, the
/// corrected sentence and a one-line explanation.
class CorrectionCard extends StatelessWidget {
  const CorrectionCard({super.key, required this.correction});

  final Correction correction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!correction.hasMistake) {
      return Chip(
        avatar: Icon(Icons.check_circle, color: colors.primary, size: 18),
        label: Text('Looks good · ${correction.score}/10'),
        visualDensity: VisualDensity.compact,
      );
    }

    return Card(
      key: const Key('correction_card'),
      color: colors.tertiaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.spellcheck,
                  size: 18,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Correction', style: theme.textTheme.labelLarge),
                ),
                Text(
                  '${correction.score}/10',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              correction.original,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: colors.onTertiaryContainer.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              correction.corrected,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onTertiaryContainer,
              ),
            ),
            if (correction.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(correction.explanation, style: theme.textTheme.bodySmall),
            ],
            if (correction.banglaExplanation case final bangla?) ...[
              const SizedBox(height: 4),
              Text(bangla, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
