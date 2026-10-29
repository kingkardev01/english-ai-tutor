import 'chat_record.dart';

/// Past chats cached on the device, readable without internet.
abstract interface class HistoryRepository {
  /// Newest first.
  Stream<List<ChatRecord>> watchAll();

  /// Adds the chat, or replaces it when one with the same id exists.
  Future<void> save(ChatRecord record);

  Future<void> delete(String id);

  Future<void> clear();
}
