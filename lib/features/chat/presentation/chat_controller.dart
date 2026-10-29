import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/tutor_failure.dart';
import '../../history/data/history_providers.dart';
import '../../history/domain/chat_record.dart';
import '../../progress/data/progress_providers.dart';
import '../../progress/domain/progress_repository.dart';
import '../data/chat_providers.dart';
import '../domain/correction.dart';
import '../domain/message.dart';
import '../domain/tutor_repository.dart';
import '../domain/tutor_settings.dart';

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
///
/// Each finished exchange and each correction is saved to progress. Saving
/// never blocks or breaks the chat; a failed save is only logged.
class ChatController extends Notifier<ChatState> {
  StreamSubscription<String>? _replySub;
  Future<String>? _session;
  late TutorSettings _settings;
  late String _historyId;
  late DateTime _startedAt;
  int _nextId = 0;

  TutorRepository get _repo => ref.read(tutorRepositoryProvider);

  /// Rebuilds, and so starts an empty chat, whenever the topic or level
  /// changes.
  @override
  ChatState build() {
    _settings = ref.watch(tutorSettingsProvider);
    _replySub?.cancel();
    _session = null;
    _startedAt = DateTime.now();
    _historyId = _startedAt.microsecondsSinceEpoch.toString();
    ref.onDispose(() => _replySub?.cancel());
    return const ChatState();
  }

  void send(String text) => _send(text);

  void _send(String text, {Correction? correction}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isReplying) return;

    final userMsg = Message(
      id: _newId(),
      role: MessageRole.user,
      text: trimmed,
      correction: correction,
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

    // A retried message keeps its first check, so it is scored only once.
    if (correction == null) unawaited(_checkGrammar(userMsg));

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
            unawaited(_saveHistory());
            final reply = state.messages
                .where((m) => m.id == tutorMsg.id)
                .firstOrNull;
            // Saved only once the exchange succeeds, so retries don't
            // duplicate messages.
            unawaited(
              _saveProgress((repo, sessionId) async {
                await repo.saveMessage(sessionId, MessageRole.user, trimmed);
                if (reply != null) {
                  await repo.saveMessage(
                    sessionId,
                    MessageRole.tutor,
                    reply.text,
                  );
                }
              }),
            );
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
    _send(failed.text, correction: failed.correction);
  }

  Future<void> _checkGrammar(Message userMsg) async {
    final topic = _settings.topic;
    final correction = await _repo.check(userMsg.text);
    if (!ref.mounted || correction == null) return;
    _update(userMsg.id, (m) => m.copyWith(correction: correction));
    unawaited(_saveHistory());
    await _saveProgress(
      (repo, sessionId) =>
          repo.recordCorrection(sessionId, correction, topic: topic),
    );
  }

  /// Keeps the finished part of this chat on the device for offline
  /// reading. Called again as replies and corrections arrive.
  Future<void> _saveHistory() async {
    final finished = [
      for (final m in state.messages)
        if (!m.isStreaming && !m.failed && m.text.isNotEmpty) m,
    ];
    if (finished.isEmpty) return;
    try {
      await ref
          .read(historyRepositoryProvider)
          .save(
            ChatRecord(
              id: _historyId,
              topic: _settings.topic,
              level: _settings.level,
              startedAt: _startedAt,
              messages: finished,
            ),
          );
    } on Object catch (e) {
      log('History not saved', error: e, name: 'ChatController');
    }
  }

  Future<void> _saveProgress(
    Future<void> Function(ProgressRepository repo, String sessionId) save,
  ) async {
    try {
      final repo = ref.read(progressRepositoryProvider);
      final session = _session ??= repo.startSession(_settings);
      final String sessionId;
      try {
        sessionId = await session;
      } on Object {
        // Let the next save try to start the session again.
        if (identical(_session, session)) _session = null;
        rethrow;
      }
      await save(repo, sessionId);
    } on Object catch (e) {
      log('Progress not saved', error: e, name: 'ChatController');
    }
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
