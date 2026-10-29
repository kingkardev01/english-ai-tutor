enum Level {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const Level(this.label);
  final String label;
}

enum Topic {
  dailyLife('Daily life'),
  jobInterview('Job interview'),
  travel('Travel'),
  ieltsSpeaking('IELTS speaking');

  const Topic(this.label);
  final String label;
}

/// The learner's chosen level and topic; both feed the system prompt.
class TutorSettings {
  const TutorSettings({
    this.level = Level.intermediate,
    this.topic = Topic.dailyLife,
    this.explainInBangla = false,
  });

  final Level level;
  final Topic topic;

  /// Adds a Bangla explanation to each correction, for beginners.
  final bool explainInBangla;

  TutorSettings copyWith({Level? level, Topic? topic, bool? explainInBangla}) =>
      TutorSettings(
        level: level ?? this.level,
        topic: topic ?? this.topic,
        explainInBangla: explainInBangla ?? this.explainInBangla,
      );
}
