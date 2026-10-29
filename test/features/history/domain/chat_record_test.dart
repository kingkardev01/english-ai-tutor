import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:english_ai_tutor/features/chat/domain/message.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:english_ai_tutor/features/history/domain/chat_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final record = ChatRecord(
    id: 'c1',
    topic: Topic.ieltsSpeaking,
    level: Level.advanced,
    startedAt: DateTime(2026, 10, 30, 9, 15),
    messages: const [
      Message(
        id: '0',
        role: MessageRole.user,
        text: 'I has two brother.',
        correction: Correction(
          original: 'I has two brother.',
          hasMistake: true,
          corrected: 'I have two brothers.',
          explanation: 'Use "have" with "I", and plural "brothers".',
          score: 5,
          banglaExplanation: '"I" এর সাথে "have" বসে।',
        ),
      ),
      Message(id: '1', role: MessageRole.tutor, text: 'Are they older?'),
    ],
  );

  test('survives a JSON round trip, including corrections', () {
    final copy = ChatRecord.fromJson(record.toJson());

    expect(copy.id, 'c1');
    expect(copy.topic, Topic.ieltsSpeaking);
    expect(copy.level, Level.advanced);
    expect(copy.startedAt, record.startedAt);
    expect(copy.messages.map((m) => m.role), [
      MessageRole.user,
      MessageRole.tutor,
    ]);
    final correction = copy.messages.first.correction!;
    expect(correction.original, 'I has two brother.');
    expect(correction.corrected, 'I have two brothers.');
    expect(correction.score, 5);
    expect(correction.banglaExplanation, '"I" এর সাথে "have" বসে।');
    expect(copy.messages.last.correction, isNull);
  });

  test('preview is the first learner message', () {
    expect(record.preview, 'I has two brother.');
  });
}
