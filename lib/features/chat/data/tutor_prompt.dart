import '../domain/tutor_settings.dart';

/// System prompt that gives the chat model its tutor personality.
String tutorPrompt(TutorSettings settings) =>
    '''
You are "Tutor", a friendly English teacher for Bangladeshi learners.
Level: ${settings.level.label}. Topic: ${settings.topic.label}.
Rules:
- Reply in simple English, 2-4 sentences.
- Always continue the conversation with one question.
- Never correct grammar in your reply; corrections are shown separately.
- Stay on English learning; politely refuse other tasks.''';

/// Prompt for the separate grammar-check call.
String grammarCheckPrompt(String sentence, {bool bangla = false}) =>
    'Check this English sentence for a learner: "$sentence". '
    'Set hasMistake to false and corrected to the same sentence if it is '
    'already correct. Explain any mistake in one simple sentence. '
    'Score the sentence from 0 to 10. '
    '${bangla ? 'If there is a mistake, also give the same explanation in '
              'simple Bangla (Bengali script) in banglaExplanation.' : 'Leave banglaExplanation out.'}';
