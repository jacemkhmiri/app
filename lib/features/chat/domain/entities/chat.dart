import 'message.dart';

class Chat {
  final String id;
  final List<String> participantIds;
  final List<Message> messages;
  final DateTime lastActivity;

  Chat({
    required this.id,
    required this.participantIds,
    required this.messages,
    required this.lastActivity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}