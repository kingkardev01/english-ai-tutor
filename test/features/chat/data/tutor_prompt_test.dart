import 'package:english_ai_tutor/features/chat/data/tutor_prompt.dart';
import 'package:english_ai_tutor/features/chat/domain/tutor_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tutorPrompt includes the level and topic', () {
    final prompt = tutorPrompt(
      const TutorSettings(level: Level.beginner, topic: Topic.jobInterview),
    );

    expect(prompt, contains('Level: Beginner'));
    expect(prompt, contains('Topic: Job interview'));
    expect(prompt, contains('Never correct grammar in your reply'));
  });

  test('grammarCheckPrompt quotes the sentence', () {
    expect(grammarCheckPrompt('I has a cat'), contains('"I has a cat"'));
  });

  test('grammarCheckPrompt asks for Bangla only when turned on', () {
    expect(grammarCheckPrompt('x'), contains('Leave banglaExplanation out'));
    expect(
      grammarCheckPrompt('x', bangla: true),
      contains('simple Bangla (Bengali script) in banglaExplanation'),
    );
  });
}
