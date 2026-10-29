import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../voice/data/voice_providers.dart';
import '../../voice/domain/voice_services.dart';
import '../data/chat_providers.dart';
import 'chat_controller.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // Read up front: providers can't be read in dispose().
  late final SpeechOutput _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(speechOutputProvider);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  /// In voice mode, reads each tutor reply aloud once it has finished.
  void _speakFinishedReplies(ChatState? previous, ChatState next) {
    if (!ref.read(voiceModeProvider)) return;
    final wasStreaming = {
      for (final m in previous?.messages ?? const [])
        if (m.isStreaming) m.id,
    };
    for (final m in next.messages) {
      if (wasStreaming.contains(m.id) && !m.isStreaming && !m.isUser) {
        _tts.speak(m.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatControllerProvider, _speakFinishedReplies);
    final voiceMode = ref.watch(voiceModeProvider);
    final state = ref.watch(chatControllerProvider);
    final settings = ref.watch(tutorSettingsProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final messages = state.messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI English Tutor'),
        actions: [
          IconButton(
            key: const Key('voice_mode_button'),
            tooltip: voiceMode ? 'Turn voice mode off' : 'Turn voice mode on',
            isSelected: voiceMode,
            icon: const Icon(Icons.voice_over_off),
            selectedIcon: const Icon(Icons.record_voice_over),
            onPressed: () {
              if (voiceMode) _tts.stop();
              ref.read(voiceModeProvider.notifier).toggle();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${settings.topic.label} · ${settings.level.label}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const _EmptyChat()
                // Reversed so the newest message stays pinned to the bottom.
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => MessageBubble(
                      key: ValueKey(messages[i].id),
                      message: messages[i],
                      onSpeak: () => _tts.speak(messages[i].text),
                    ),
                  ),
          ),
          if (state.failure case final failure?)
            _ErrorBanner(message: failure.message, onRetry: controller.retry),
          ChatInput(enabled: !state.isReplying, onSend: controller.send),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Say hello to start practising',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your tutor replies in simple English and checks every sentence you write.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              key: const Key('retry_button'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
