/// A past grammar mistake, kept for review.
class Mistake {
  const Mistake({
    required this.id,
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.createdAt,
    this.topic,
    this.reviewed = false,
  });

  /// Reads the local-storage format, where `createdAt` is an ISO string.
  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
    id: json['id'] as String,
    original: json['original'] as String,
    corrected: json['corrected'] as String,
    explanation: json['explanation'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    topic: json['topic'] as String?,
    reviewed: json['reviewed'] as bool? ?? false,
  );

  final String id;
  final String original;
  final String corrected;
  final String explanation;
  final DateTime createdAt;

  /// Label of the practice topic it came from.
  final String? topic;

  /// True once the learner has marked it as learned.
  final bool reviewed;

  Mistake copyWith({bool? reviewed}) => Mistake(
    id: id,
    original: original,
    corrected: corrected,
    explanation: explanation,
    createdAt: createdAt,
    topic: topic,
    reviewed: reviewed ?? this.reviewed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'original': original,
    'corrected': corrected,
    'explanation': explanation,
    'createdAt': createdAt.toIso8601String(),
    'topic': topic,
    'reviewed': reviewed,
  };
}
