import 'package:frontend/Model/message_model.dart';
import 'package:frontend/Model/user_model.dart';

class Conversation {
  User? partner;
  Message? latestMessage;
  int? unreadCount;

  Conversation({
    required this.partner,
    required this.latestMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      partner: User.fromJson(json['partner']),
      latestMessage: Message.fromJson(json['latestMessage']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
