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
