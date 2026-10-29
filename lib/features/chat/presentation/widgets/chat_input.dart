import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../voice/data/voice_providers.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key, required this.enabled, required this.onSend});

  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  bool _listening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _toggleMic() async {
    final speech = ref.read(speechInputProvider);
    if (_listening) {
      await speech.stop();
      return;
    }
    if (!await speech.initialize()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is not available. '
            'Check microphone permission.',
          ),
        ),
      );
      return;
    }
    // Don't let the tutor's voice be picked up by the microphone.
    await ref.read(speechOutputProvider).stop();
    if (!mounted) return;
    setState(() => _listening = true);
    await speech.listen(
      onResult: (words, isFinal) {
        if (!mounted) return;
        _controller.text = words;
        if (isFinal && ref.read(voiceModeProvider)) _send();
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              key: const Key('mic_button'),
              onPressed: widget.enabled ? _toggleMic : null,
              tooltip: _listening ? 'Stop listening' : 'Speak',
              icon: Icon(
                _listening ? Icons.mic : Icons.mic_none,
                color: _listening ? colors.error : null,
              ),
            ),
            Expanded(
              child: TextField(
                key: const Key('chat_input'),
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _listening ? 'Listening…' : 'Write in English…',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              key: const Key('send_button'),
              onPressed: widget.enabled ? _send : null,
              icon: const Icon(Icons.send),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
