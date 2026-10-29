import 'dart:async';

import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/message.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/progress/domain/mistake.dart';
import 'package:english_ai_tutor/features/progress/domain/progress.dart';
import 'package:english_ai_tutor/features/progress/domain/progress_repository.dart';

/// Records every call so tests can check what the app saved.
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({
    this.progress = const Progress(),
    List<Mistake> mistakes = const [],
  }) : mistakes = [...mistakes];

  Progress progress;
  List<Mistake> mistakes;
  final sessions = <TutorSettings>[];
  final savedMessages = <(String sessionId, MessageRole role, String text)>[];
  final recorded = <(String sessionId, Correction correction, Topic topic)>[];
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<Progress> watchProgress() async* {
    yield progress;
    await for (final _ in _changes.stream) {
      yield progress;
    }
  }

  @override
  Stream<List<Mistake>> watchMistakes() async* {
    yield mistakes;
    await for (final _ in _changes.stream) {
      yield mistakes;
    }
  }

  @override
  Future<String> startSession(TutorSettings settings) async {
    sessions.add(settings);
    return 'session-${sessions.length}';
  }

  @override
  Future<void> saveMessage(
    String sessionId,
    MessageRole role,
    String text,
  ) async => savedMessages.add((sessionId, role, text));

  @override
  Future<void> recordCorrection(
    String sessionId,
    Correction correction, {
    required Topic topic,
  }) async => recorded.add((sessionId, correction, topic));

  @override
  Future<void> setReviewed(String mistakeId, {required bool reviewed}) async {
    mistakes = [
      for (final m in mistakes)
        m.id == mistakeId ? m.copyWith(reviewed: reviewed) : m,
    ];
    _changes.add(null);
  }
}
