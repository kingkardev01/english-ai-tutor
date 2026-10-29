import '../../chat/domain/message.dart';
import '../../chat/domain/tutor_settings.dart';

/// One past practice chat, kept on the device for offline reading.
class ChatRecord {
  const ChatRecord({
    required this.id,
    required this.topic,
    required this.level,
    required this.startedAt,
    required this.messages,
  });

  factory ChatRecord.fromJson(Map<String, dynamic> json) => ChatRecord(
    id: json['id'] as String,
    topic: Topic.values.byName(json['topic'] as String),
    level: Level.values.byName(json['level'] as String),
    startedAt: DateTime.parse(json['startedAt'] as String),
    messages: [
      for (final m in json['messages'] as List)
        Message.fromJson(m as Map<String, dynamic>),
    ],
  );

  final String id;
  final Topic topic;
  final Level level;
  final DateTime startedAt;
  final List<Message> messages;

  /// The learner's first message, used as the chat's title in the list.
  String get preview => messages.where((m) => m.isUser).firstOrNull?.text ?? '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic.name,
    'level': level.name,
    'startedAt': startedAt.toIso8601String(),
    'messages': [for (final m in messages) m.toJson()],
  };
}
