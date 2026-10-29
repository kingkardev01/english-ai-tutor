import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/constants/ai_constants.dart';
import '../../../core/errors/tutor_failure.dart';
import '../domain/correction.dart';
import '../domain/tutor_repository.dart';
import 'ai_service.dart';
import 'gemini_api_service.dart';

class ChatRepositoryImpl implements TutorRepository {
  ChatRepositoryImpl(this._ai);

  final AiService _ai;

  @override
  Stream<String> reply(String message) async* {
    var gotText = false;
    try {
      await for (final chunk in _ai.reply(message)) {
        if (chunk.isEmpty) continue;
        gotText = true;
        yield chunk;
      }
    } on Object catch (e) {
      // A blocked reply is not an error for the learner; keep the chat going.
      if (!isBlocked(e)) throw mapAiError(e);
    }
    if (!gotText) yield kFallbackReply;
  }

  @override
  Future<Correction?> check(String sentence) async {
    try {
      final raw = await _ai.checkGrammar(sentence);
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return Correction.fromJson(sentence, json);
    } on Object catch (e) {
      log('Grammar check skipped', error: e, name: 'ChatRepository');
      return null;
    }
  }
}

bool isBlocked(Object error) =>
    error is FirebaseAIException &&
    error.message.toLowerCase().contains('blocked');

/// Maps SDK and network errors to failures the UI can explain.
TutorFailure mapAiError(Object error) {
  if (error is TutorFailure) return error;
  if (error is QuotaExceeded) return const TutorBusyFailure();
  if (error is GeminiApiException && error.statusCode == 429) {
    return const TutorBusyFailure();
  }
  if (error is TimeoutException) return const NoConnectionFailure();

  final text = error.toString().toLowerCase();
  const busyHints = ['quota', 'rate limit', 'resource_exhausted', '429'];
  const offlineHints = [
    'socketexception',
    'clientexception',
    'failed host lookup',
    'network',
    'connection',
  ];
  if (busyHints.any(text.contains)) return const TutorBusyFailure();
  if (offlineHints.any(text.contains)) return const NoConnectionFailure();
  return UnknownFailure(error);
}
