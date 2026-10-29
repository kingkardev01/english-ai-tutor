import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/presentation/widgets/message_bubble.dart';
import '../data/history_providers.dart';
import '../domain/chat_record.dart';

/// Past chats saved on the device; they open without internet.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(historyProvider).value ?? const <ChatRecord>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat history'),
        actions: [
          if (chats.isNotEmpty)
            IconButton(
              tooltip: 'Delete all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: chats.isEmpty
          ? const Center(child: Text('Your past chats will appear here.'))
          : ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final chat = chats[i];
                return Dismissible(
                  key: ValueKey(chat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) =>
                      ref.read(historyRepositoryProvider).delete(chat.id),
                  child: ListTile(
                    title: Text(
                      chat.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${chat.topic.label} · ${chat.level.label} · '
                      '${_dateTime(chat.startedAt)}',
                    ),
                    trailing: Text('${chat.messages.length}'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoryDetailScreen(chat: chat),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all chats?'),
        content: const Text(
          'This removes chat history from this phone. '
          'Your progress and mistakes are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(historyRepositoryProvider).clear();
  }
}

/// Read-only view of one past chat, with its correction cards.
class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.chat});

  final ChatRecord chat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chat.topic.label),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${chat.level.label} · ${_dateTime(chat.startedAt)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: chat.messages.length,
        itemBuilder: (_, i) => MessageBubble(message: chat.messages[i]),
      ),
    );
  }
}

String _dateTime(DateTime d) {
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
  final l = d.toLocal();
  final minute = l.minute.toString().padLeft(2, '0');
  return '${l.day} ${months[l.month - 1]}, ${l.hour}:$minute';
}
