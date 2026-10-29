import 'package:english_ai_tutor/core/errors/tutor_failure.dart';
import 'package:english_ai_tutor/features/chat/data/chat_providers.dart';
import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/message.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/chat/presentation/chat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_history_repository.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/fake_tutor_repository.dart';
import '../../../helpers/test_overrides.dart';

void main() {
  late FakeTutorRepository repo;
  late FakeProgressRepository progress;
  late FakeHistoryRepository history;
  late ProviderContainer container;

  ChatState state() => container.read(chatControllerProvider);
  ChatController controller() =>
      container.read(chatControllerProvider.notifier);

  setUp(() {
    repo = FakeTutorRepository();
    progress = FakeProgressRepository();
    history = FakeHistoryRepository();
    container = ProviderContainer(
      overrides: testOverrides(
        tutor: repo,
        progress: progress,
        history: history,
      ),
    );
  });

  tearDown(() => container.dispose());

  test('streams the reply into one tutor message', () async {
    controller().send('Hello');

    expect(state().isReplying, isTrue);
    expect(state().messages.map((m) => m.role), [
      MessageRole.user,
      MessageRole.tutor,
    ]);

    repo.emit('Hi! ');
    repo.emit('How are you?');
    await Future<void>.delayed(Duration.zero);
    expect(state().messages.last.text, 'Hi! How are you?');
    expect(state().messages.last.isStreaming, isTrue);

    await repo.finish();
    await Future<void>.delayed(Duration.zero);
    expect(state().isReplying, isFalse);
    expect(state().messages.last.isStreaming, isFalse);
  });

  test('attaches the grammar correction to the user message', () async {
    repo.correctionFor = (s) => Correction(
      original: s,
      hasMistake: true,
      corrected: 'I am fine',
      explanation: 'Use am with I.',
      score: 6,
    );

    controller().send('I is fine');
    await Future<void>.delayed(Duration.zero);

    expect(repo.checkedSentences, ['I is fine']);
    expect(state().messages.first.correction?.corrected, 'I am fine');
  });

  test('ignores blank messages and messages sent while replying', () {
    controller().send('   ');
    expect(state().messages, isEmpty);

    controller().send('First');
    controller().send('Second');
    expect(repo.sentMessages, ['First']);
  });

  test(
    'on failure keeps the message, shows the error, and retry resends',
    () async {
      controller().send('Hello');
      repo.fail(const NoConnectionFailure());
      await Future<void>.delayed(Duration.zero);

      expect(state().failure, isA<NoConnectionFailure>());
      expect(state().isReplying, isFalse);
      expect(state().messages, hasLength(1));
      expect(state().messages.single.failed, isTrue);

      controller().retry();

      expect(repo.sentMessages, ['Hello', 'Hello']);
      expect(state().failure, isNull);
      expect(state().messages.where((m) => m.failed), isEmpty);
    },
  );

  group('progress', () {
    Correction mistakeIn(String s) => Correction(
      original: s,
      hasMistake: true,
      corrected: 'fixed',
      explanation: '',
      score: 5,
    );

    test('records each correction with the current topic', () async {
      container.read(tutorSettingsProvider.notifier).startTopic(Topic.travel);
      repo.correctionFor = mistakeIn;

      controller().send('I goed there');
      await pumpEventQueue();

      expect(progress.sessions.single.topic, Topic.travel);
      final (sessionId, correction, topic) = progress.recorded.single;
      expect(sessionId, 'session-1');
      expect(correction.original, 'I goed there');
      expect(topic, Topic.travel);
    });

    test('saves both messages once the reply finishes', () async {
      controller().send('Hello');
      repo.emit('Hi there!');
      await repo.finish();
      await pumpEventQueue();

      expect(progress.savedMessages, [
        ('session-1', MessageRole.user, 'Hello'),
        ('session-1', MessageRole.tutor, 'Hi there!'),
      ]);
    });

    test('a failed reply saves nothing, and retry scores only once', () async {
      repo.correctionFor = mistakeIn;
      controller().send('Hello');
      await pumpEventQueue();
      repo.fail(const NoConnectionFailure());
      await pumpEventQueue();
      expect(progress.savedMessages, isEmpty);

      controller().retry();
      await repo.finish();
      await pumpEventQueue();

      expect(repo.checkedSentences, ['Hello']);
      expect(progress.recorded, hasLength(1));
      expect(progress.savedMessages, hasLength(2));
    });

    test('a new topic clears the chat and starts a new session', () async {
      controller().send('Hello');
      await repo.finish();
      await pumpEventQueue();

      container.read(tutorSettingsProvider.notifier).startTopic(Topic.travel);
      expect(state().messages, isEmpty);

      controller().send('Hi again');
      await repo.finish();
      await pumpEventQueue();
      expect(progress.sessions.map((s) => s.topic), [
        Topic.dailyLife,
        Topic.travel,
      ]);
    });
  });

  test('saves the finished chat, with corrections, to history', () async {
    container.read(tutorSettingsProvider.notifier).startTopic(Topic.travel);
    repo.correctionFor = (s) => Correction(
      original: s,
      hasMistake: true,
      corrected: 'I went there.',
      explanation: '',
      score: 5,
    );

    controller().send('I goed there.');
    repo.emit('Nice!');
    await repo.finish();
    await pumpEventQueue();

    final chat = history.chats.values.single;
    expect(chat.topic, Topic.travel);
    expect(chat.messages.map((m) => m.text), ['I goed there.', 'Nice!']);
    expect(chat.messages.first.correction?.corrected, 'I went there.');
  });
}
