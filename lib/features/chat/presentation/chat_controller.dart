import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/tutor_failure.dart';
import '../data/chat_providers.dart';
import '../domain/message.dart';
import '../domain/tutor_repository.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isReplying = false,
    this.failure,
  });

  final List<Message> messages;
  final bool isReplying;

  /// The last failed reply, shown with a retry button.
  final TutorFailure? failure;

  ChatState copyWith({
    List<Message>? messages,
    bool? isReplying,
    TutorFailure? failure,
    bool clearFailure = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isReplying: isReplying ?? this.isReplying,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

/// Runs the streaming reply and the grammar check in parallel, so the
/// reply starts immediately and the correction card appears when ready.
class ChatController extends Notifier<ChatState> {
  StreamSubscription<String>? _replySub;
  int _nextId = 0;

  TutorRepository get _repo => ref.read(tutorRepositoryProvider);

  @override
  ChatState build() {
    ref.onDispose(() => _replySub?.cancel());
    return const ChatState();
  }

  void send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isReplying) return;

    final userMsg = Message(
      id: _newId(),
      role: MessageRole.user,
      text: trimmed,
    );
    final tutorMsg = Message(
      id: _newId(),
      role: MessageRole.tutor,
      text: '',
      isStreaming: true,
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg, tutorMsg],
      isReplying: true,
      clearFailure: true,
    );

    unawaited(_checkGrammar(userMsg));

    _replySub = _repo
        .reply(trimmed)
        .listen(
          (chunk) =>
              _update(tutorMsg.id, (m) => m.copyWith(text: m.text + chunk)),
          onError: (Object error) =>
              _onReplyFailed(userMsg.id, tutorMsg.id, error),
          onDone: () {
            _update(tutorMsg.id, (m) => m.copyWith(isStreaming: false));
            state = state.copyWith(isReplying: false);
          },
          cancelOnError: true,
        );
  }

  /// Resends the last message whose reply failed.
  void retry() {
    final failed = state.messages.where((m) => m.failed).lastOrNull;
    if (failed == null) return;
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != failed.id).toList(),
      clearFailure: true,
    );
    send(failed.text);
  }

  Future<void> _checkGrammar(Message userMsg) async {
    final correction = await _repo.check(userMsg.text);
    if (!ref.mounted || correction == null) return;
    _update(userMsg.id, (m) => m.copyWith(correction: correction));
  }

  void _onReplyFailed(String userId, String tutorId, Object error) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == userId)
            m.copyWith(failed: true)
          else if (m.id != tutorId)
            m,
      ],
      isReplying: false,
      failure: error is TutorFailure ? error : UnknownFailure(error),
    );
  }

  void _update(String id, Message Function(Message) change) {
    state = state.copyWith(
      messages: [for (final m in state.messages) m.id == id ? change(m) : m],
    );
  }

  String _newId() => '${_nextId++}';
}
