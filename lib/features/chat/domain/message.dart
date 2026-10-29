import 'correction.dart';

enum MessageRole { user, tutor }

/// One bubble in the chat.
class Message {
  const Message({
    required this.id,
    required this.role,
    required this.text,
    this.correction,
    this.isStreaming = false,
    this.failed = false,
  });

  /// Reads a message saved by [toJson].
  factory Message.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String;
    final correction = json['correction'] as Map<String, dynamic>?;
    return Message(
      id: json['id'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      text: text,
      correction: correction == null
          ? null
          : Correction.fromJson(text, correction),
    );
  }

  final String id;
  final MessageRole role;
  final String text;

  /// Grammar check for a user message; null until it arrives, or when the
  /// check failed.
  final Correction? correction;

  /// True while the tutor's reply is still arriving.
  final bool isStreaming;

  /// True for a user message whose reply failed and can be retried.
  final bool failed;

  bool get isUser => role == MessageRole.user;

  /// Only finished messages are saved, so streaming and failure flags are
  /// left out.
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'correction': ?correction?.toJson(),
  };

  Message copyWith({
    String? text,
    Correction? correction,
    bool? isStreaming,
    bool? failed,
  }) {
    return Message(
      id: id,
      role: role,
      text: text ?? this.text,
      correction: correction ?? this.correction,
      isStreaming: isStreaming ?? this.isStreaming,
      failed: failed ?? this.failed,
    );
  }
}
