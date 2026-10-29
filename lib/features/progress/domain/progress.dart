import '../../../core/utils/date_key.dart';

/// The learner's overall progress, stored on `users/{uid}`.
class Progress {
  const Progress({
    this.streakDays = 0,
    this.lastPracticeDate,
    this.totalScore = 0,
    this.sentencesChecked = 0,
  });

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
    streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
    lastPracticeDate: json['lastPracticeDate'] as String?,
    totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
    sentencesChecked: (json['sentencesChecked'] as num?)?.toInt() ?? 0,
  );

  final int streakDays;

  /// Last day with practice, as `yyyy-MM-dd`.
  final String? lastPracticeDate;

  /// Sum of all sentence scores (each 0-10).
  final int totalScore;
  final int sentencesChecked;

  /// Average sentence score out of 10, or null before the first sentence.
  double? get averageScore =>
      sentencesChecked == 0 ? null : totalScore / sentencesChecked;

  /// The streak as it stands [now]: it is lost once a whole day passes
  /// without practice.
  int currentStreak(DateTime now) {
    final last = lastPracticeDate;
    if (last == dateKey(now) || last == previousDateKey(now)) {
      return streakDays;
    }
    return 0;
  }

  /// Progress after one more checked sentence with [score], practised [now].
  Progress record(int score, DateTime now) {
    final today = dateKey(now);
    final streak = switch (lastPracticeDate) {
      final last? when last == today => streakDays,
      final last? when last == previousDateKey(now) => streakDays + 1,
      _ => 1,
    };
    return Progress(
      streakDays: streak,
      lastPracticeDate: today,
      totalScore: totalScore + score,
      sentencesChecked: sentencesChecked + 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'streakDays': streakDays,
    'lastPracticeDate': lastPracticeDate,
    'totalScore': totalScore,
    'sentencesChecked': sentencesChecked,
  };
}
