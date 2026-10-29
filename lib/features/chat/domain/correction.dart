/// The result of checking one learner sentence for grammar mistakes.
class Correction {
  const Correction({
    required this.original,
    required this.hasMistake,
    required this.corrected,
    required this.explanation,
    required this.score,
    this.banglaExplanation,
  });

  /// Parses the JSON returned by the grammar-check call.
  ///
  /// Throws a [FormatException] when required fields are missing or have
  /// the wrong type, so callers can skip the card instead of crashing.
  factory Correction.fromJson(String original, Map<String, dynamic> json) {
    final hasMistake = json['hasMistake'];
    final score = json['score'];
    if (hasMistake is! bool || score is! num) {
      throw FormatException('Invalid correction JSON: $json');
    }
    return Correction(
      original: original,
      hasMistake: hasMistake,
      corrected: (json['corrected'] as String?)?.trim() ?? original,
      explanation: (json['explanation'] as String?)?.trim() ?? '',
      score: score.round().clamp(0, 10),
      banglaExplanation: switch ((json['banglaExplanation'] as String?)
          ?.trim()) {
        final text? when text.isNotEmpty => text,
        _ => null,
      },
    );
  }

  final String original;
  final bool hasMistake;
  final String corrected;
  final String explanation;

  /// 0-10, where 10 is a perfect sentence.
  final int score;

  /// Only present when Bangla explanations are on.
  final String? banglaExplanation;

  Map<String, dynamic> toJson() => {
    'original': original,
    'hasMistake': hasMistake,
    'corrected': corrected,
    'explanation': explanation,
    'score': score,
    'banglaExplanation': ?banglaExplanation,
  };
}
