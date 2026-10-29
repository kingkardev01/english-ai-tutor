import 'package:english_ai_tutor/features/progress/domain/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final monday = DateTime(2026, 10, 26, 9);
  final tuesday = DateTime(2026, 10, 27, 21);
  final thursday = DateTime(2026, 10, 29, 8);

  group('record', () {
    test('the first sentence starts a 1-day streak', () {
      final p = const Progress().record(8, monday);

      expect(p.streakDays, 1);
      expect(p.lastPracticeDate, '2026-10-26');
      expect(p.totalScore, 8);
      expect(p.sentencesChecked, 1);
    });

    test('practising again the same day keeps the streak', () {
      final p = const Progress().record(8, monday).record(6, monday);

      expect(p.streakDays, 1);
      expect(p.sentencesChecked, 2);
    });

    test('practising the next day grows the streak', () {
      final p = const Progress().record(8, monday).record(6, tuesday);

      expect(p.streakDays, 2);
    });

    test('missing a day resets the streak to 1', () {
      final p = const Progress()
          .record(8, monday)
          .record(6, tuesday)
          .record(7, thursday);

      expect(p.streakDays, 1);
      expect(p.totalScore, 21);
    });

    test('works across a month boundary', () {
      final p = const Progress()
          .record(5, DateTime(2026, 10, 31))
          .record(5, DateTime(2026, 11, 1));

      expect(p.streakDays, 2);
    });
  });

  group('currentStreak', () {
    final practised = const Progress().record(8, monday).record(6, tuesday);

    test('counts while the last practice was today or yesterday', () {
      expect(practised.currentStreak(tuesday), 2);
      expect(practised.currentStreak(DateTime(2026, 10, 28, 23)), 2);
    });

    test('is 0 once a full day is missed', () {
      expect(practised.currentStreak(thursday), 0);
    });
  });

  test('averageScore is null before any sentence, then the mean', () {
    expect(const Progress().averageScore, isNull);
    expect(
      const Progress().record(8, monday).record(5, monday).averageScore,
      6.5,
    );
  });

  test('survives a JSON round trip', () {
    final p = const Progress().record(9, monday);
    final copy = Progress.fromJson(p.toJson());

    expect(copy.streakDays, p.streakDays);
    expect(copy.lastPracticeDate, p.lastPracticeDate);
    expect(copy.totalScore, p.totalScore);
    expect(copy.sentencesChecked, p.sentencesChecked);
  });
}
