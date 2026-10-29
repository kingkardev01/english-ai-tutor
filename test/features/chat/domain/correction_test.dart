import 'package:english_ai_tutor/features/chat/domain/correction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Correction.fromJson', () {
    test('parses a full correction', () {
      final c = Correction.fromJson('I goes to school', {
        'hasMistake': true,
        'corrected': 'I go to school',
        'explanation': 'Use "go" with "I".',
        'score': 6,
      });

      expect(c.original, 'I goes to school');
      expect(c.hasMistake, isTrue);
      expect(c.corrected, 'I go to school');
      expect(c.explanation, 'Use "go" with "I".');
      expect(c.score, 6);
    });

    test('falls back to the original when corrected is missing', () {
      final c = Correction.fromJson('Hello', {
        'hasMistake': false,
        'score': 10,
      });

      expect(c.corrected, 'Hello');
      expect(c.explanation, isEmpty);
    });

    test('clamps the score to 0-10 and rounds doubles', () {
      expect(
        Correction.fromJson('a', {'hasMistake': false, 'score': 42}).score,
        10,
      );
      expect(
        Correction.fromJson('a', {'hasMistake': true, 'score': -3}).score,
        0,
      );
      expect(
        Correction.fromJson('a', {'hasMistake': true, 'score': 7.6}).score,
        8,
      );
    });

    test('throws FormatException on wrong types', () {
      expect(
        () => Correction.fromJson('a', {'hasMistake': 'yes', 'score': 5}),
        throwsFormatException,
      );
      expect(
        () => Correction.fromJson('a', {'hasMistake': true}),
        throwsFormatException,
      );
    });
  });

  group('banglaExplanation', () {
    test('is read when present', () {
      final c = Correction.fromJson('a', {
        'hasMistake': true,
        'score': 5,
        'banglaExplanation': ' এখানে "go" হবে। ',
      });
      expect(c.banglaExplanation, 'এখানে "go" হবে।');
      expect(c.toJson()['banglaExplanation'], 'এখানে "go" হবে।');
    });

    test('is null when missing or blank', () {
      expect(
        Correction.fromJson('a', {
          'hasMistake': false,
          'score': 10,
        }).banglaExplanation,
        isNull,
      );
      expect(
        Correction.fromJson('a', {
          'hasMistake': false,
          'score': 10,
          'banglaExplanation': '  ',
        }).banglaExplanation,
        isNull,
      );
    });
  });
}
