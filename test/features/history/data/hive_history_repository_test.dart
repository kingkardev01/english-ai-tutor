import 'dart:io';

import 'package:english_ai_tutor/features/chat/domain/message.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/history/data/hive_history_repository.dart';
import 'package:english_ai_tutor/features/history/domain/chat_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

ChatRecord chat(String id, DateTime startedAt, [String text = 'Hello']) =>
    ChatRecord(
      id: id,
      topic: Topic.travel,
      level: Level.beginner,
      startedAt: startedAt,
      messages: [Message(id: '0', role: MessageRole.user, text: text)],
    );

void main() {
  late Directory dir;
  late Box<String> box;
  late HiveHistoryRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('history_test');
    Hive.init(dir.path);
    box = await Hive.openBox<String>(HiveHistoryRepository.boxName);
    repo = HiveHistoryRepository(box);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('returns chats newest first', () async {
    await repo.save(chat('old', DateTime(2026, 10, 1)));
    await repo.save(chat('new', DateTime(2026, 10, 2)));

    final chats = await repo.watchAll().first;
    expect(chats.map((c) => c.id), ['new', 'old']);
  });

  test('saving the same id replaces the chat', () async {
    await repo.save(chat('a', DateTime(2026, 10, 1), 'first'));
    await repo.save(chat('a', DateTime(2026, 10, 1), 'updated'));

    final chats = await repo.watchAll().first;
    expect(chats.single.preview, 'updated');
  });

  test(
    'keeps only the newest ${HiveHistoryRepository.maxChats} chats',
    () async {
      for (var i = 0; i < HiveHistoryRepository.maxChats + 3; i++) {
        await repo.save(
          chat('c$i', DateTime(2026, 1, 1).add(Duration(hours: i))),
        );
      }

      final chats = await repo.watchAll().first;
      expect(chats, hasLength(HiveHistoryRepository.maxChats));
      expect(chats.map((c) => c.id), isNot(contains('c0')));
      expect(chats.first.id, 'c${HiveHistoryRepository.maxChats + 2}');
    },
  );

  test('watchAll updates on save, delete and clear', () async {
    final sizes = repo.watchAll().map((c) => c.length);
    final expectation = expectLater(sizes, emitsInOrder([0, 1, 2, 1, 0]));
    await pumpEventQueue();

    await repo.save(chat('a', DateTime(2026, 10, 1)));
    await repo.save(chat('b', DateTime(2026, 10, 2)));
    await repo.delete('a');
    await repo.clear();
    await expectation;
  });

  test('chats are still there after reopening the box', () async {
    await repo.save(chat('a', DateTime(2026, 10, 1)));
    await box.close();

    final reopened = HiveHistoryRepository(
      await Hive.openBox<String>(HiveHistoryRepository.boxName),
    );
    expect((await reopened.watchAll().first).single.id, 'a');
  });
}
