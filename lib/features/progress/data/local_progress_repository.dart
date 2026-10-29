import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../chat/domain/correction.dart';
import '../../chat/domain/message.dart';
import '../../chat/domain/tutor_settings.dart';
import '../domain/mistake.dart';
import '../domain/progress.dart';
import '../domain/progress_repository.dart';

/// Keeps progress and mistakes on the device, for running the app with
/// only a Gemini API key (no Firebase sign-in).
///
/// Chat messages are not stored here; offline chat history is Phase 3.
class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _progressKey = 'progress';
  static const _mistakesKey = 'mistakes';
  static const _mistakeLimit = 200;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final _changes = StreamController<void>.broadcast();

  Progress get _progress {
    final raw = _prefs.getString(_progressKey);
    return raw == null
        ? const Progress()
        : Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  List<Mistake> get _mistakes {
    final raw = _prefs.getString(_mistakesKey);
    if (raw == null) return const [];
    return [
      for (final m in jsonDecode(raw) as List)
        Mistake.fromJson(m as Map<String, dynamic>),
    ];
  }

  @override
  Stream<Progress> watchProgress() => _watch(() => _progress);

  @override
  Stream<List<Mistake>> watchMistakes() => _watch(() => _mistakes);

  @override
  Future<String> startSession(TutorSettings settings) async =>
      _clock().microsecondsSinceEpoch.toString();

  @override
  Future<void> saveMessage(
    String sessionId,
    MessageRole role,
    String text,
  ) async {}

  @override
  Future<void> recordCorrection(
    String sessionId,
    Correction correction, {
    required Topic topic,
  }) async {
    final now = _clock();
    await _prefs.setString(
      _progressKey,
      jsonEncode(_progress.record(correction.score, now).toJson()),
    );
    if (correction.hasMistake) {
      final mistake = Mistake(
        id: now.microsecondsSinceEpoch.toString(),
        original: correction.original,
        corrected: correction.corrected,
        explanation: correction.explanation,
        topic: topic.label,
        banglaExplanation: correction.banglaExplanation,
        createdAt: now,
      );
      await _saveMistakes([mistake, ..._mistakes].take(_mistakeLimit).toList());
    }
    _changes.add(null);
  }

  @override
  Future<void> setReviewed(String mistakeId, {required bool reviewed}) async {
    await _saveMistakes([
      for (final m in _mistakes)
        m.id == mistakeId ? m.copyWith(reviewed: reviewed) : m,
    ]);
    _changes.add(null);
  }

  void dispose() => _changes.close();

  Future<void> _saveMistakes(List<Mistake> mistakes) => _prefs.setString(
    _mistakesKey,
    jsonEncode([for (final m in mistakes) m.toJson()]),
  );

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }
}
