import 'package:flutter/material.dart';

import '../../domain/message.dart';
import 'correction_card.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.onSpeak});

  final Message message;

  /// Reads a finished tutor reply aloud; no speaker button when null.
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUser = message.isUser;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.8;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: message.isStreaming && message.text.isEmpty
          ? const _TypingIndicator()
          : Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isUser ? colors.onPrimary : colors.onSurface,
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          bubble,
          if (onSpeak != null &&
              !isUser &&
              !message.isStreaming &&
              message.text.isNotEmpty)
            IconButton(
              tooltip: 'Listen',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_outlined),
            ),
          if (message.failed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Not sent',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          if (message.correction case final correction?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: CorrectionCard(correction: correction),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 20,
      child: Center(
        child: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
