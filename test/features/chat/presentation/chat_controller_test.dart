import 'package:english_ai_tutor/core/errors/tutor_failure.dart';
import 'package:english_ai_tutor/features/chat/data/chat_providers.dart';
import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/message.dart';
import 'package:english_ai_tutor/features/chat/presentation/chat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_tutor_repository.dart';

void main() {
  late FakeTutorRepository repo;
  late ProviderContainer container;

  ChatState state() => container.read(chatControllerProvider);
  ChatController controller() =>
      container.read(chatControllerProvider.notifier);

  setUp(() {
    repo = FakeTutorRepository();
    container = ProviderContainer(
      overrides: [tutorRepositoryProvider.overrideWithValue(repo)],
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
}
