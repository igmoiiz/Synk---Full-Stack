import 'package:frontend/Model/user_model.dart';
import 'package:intl/intl.dart';

class Message {
  String? id;
  User? sender;
  User? receiver;
  String? content;
  DateTime? createdAt;
  bool? read;

  Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.createdAt,
    required this.read,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      sender: User.fromJson(json['sender']),
      receiver: User.fromJson(json['receiver']),
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  String getFormattedTime() {
    return DateFormat('h:mm a').format(createdAt!);
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(
      createdAt!.year,
      createdAt!.month,
      createdAt!.day,
    );

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(createdAt!);
    }
  }
}
