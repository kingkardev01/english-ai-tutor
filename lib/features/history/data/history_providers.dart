import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../domain/chat_record.dart';
import '../domain/history_repository.dart';
import 'hive_history_repository.dart';

/// Overridden in main() with the opened box.
final historyBoxProvider = Provider<Box<String>>(
  (ref) => throw UnimplementedError('Override historyBoxProvider'),
);

/// Override this in tests with a fake.
final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HiveHistoryRepository(ref.watch(historyBoxProvider)),
);

final historyProvider = StreamProvider<List<ChatRecord>>(
  (ref) => ref.watch(historyRepositoryProvider).watchAll(),
);
