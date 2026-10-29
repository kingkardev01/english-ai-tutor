import 'dart:async';

import 'package:english_ai_tutor/features/history/domain/chat_record.dart';
import 'package:english_ai_tutor/features/history/domain/history_repository.dart';

class FakeHistoryRepository implements HistoryRepository {
  FakeHistoryRepository([List<ChatRecord> chats = const []])
    : chats = {for (final c in chats) c.id: c};

  final Map<String, ChatRecord> chats;
  final _changes = StreamController<void>.broadcast();

  List<ChatRecord> get _sorted =>
      chats.values.toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  @override
  Stream<List<ChatRecord>> watchAll() async* {
    yield _sorted;
    await for (final _ in _changes.stream) {
      yield _sorted;
    }
  }

  @override
  Future<void> save(ChatRecord record) async {
    chats[record.id] = record;
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    chats.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> clear() async {
    chats.clear();
    _changes.add(null);
  }
}
