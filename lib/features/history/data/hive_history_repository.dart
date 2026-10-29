import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../domain/chat_record.dart';
import '../domain/history_repository.dart';

/// Stores each chat as a JSON string keyed by its id, so no Hive type
/// adapters or code generation are needed.
class HiveHistoryRepository implements HistoryRepository {
  HiveHistoryRepository(this._box);

  static const boxName = 'chat_history';

  /// Older chats are dropped beyond this, to keep storage small.
  static const maxChats = 50;

  final Box<String> _box;

  List<ChatRecord> _readAll() {
    final records = [
      for (final raw in _box.values)
        ChatRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    ];
    return records..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  @override
  Stream<List<ChatRecord>> watchAll() async* {
    yield _readAll();
    await for (final _ in _box.watch()) {
      yield _readAll();
    }
  }

  @override
  Future<void> save(ChatRecord record) async {
    await _box.put(record.id, jsonEncode(record.toJson()));
    final all = _readAll();
    if (all.length > maxChats) {
      await _box.deleteAll(all.skip(maxChats).map((r) => r.id));
    }
  }

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<void> clear() => _box.clear();
}
