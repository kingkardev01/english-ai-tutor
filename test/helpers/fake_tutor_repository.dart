import 'dart:async';

import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_repository.dart';

/// A hand-driven repository: tests push reply chunks and finish or fail
/// the stream when they want, to check each streaming state.
class FakeTutorRepository implements TutorRepository {
  final sentMessages = <String>[];
  final checkedSentences = <String>[];
  StreamController<String>? _reply;

  /// Returned by [check]; null skips the correction card.
  Correction? Function(String sentence) correctionFor = (_) => null;

  @override
  Stream<String> reply(String message) {
    sentMessages.add(message);
    _reply = StreamController<String>();
    return _reply!.stream;
  }

  @override
  Future<Correction?> check(String sentence) async {
    checkedSentences.add(sentence);
    return correctionFor(sentence);
  }

  void emit(String chunk) => _reply!.add(chunk);

  Future<void> finish() => _reply!.close();

  void fail(Object error) {
    _reply!.addError(error);
    _reply!.close();
  }
}
