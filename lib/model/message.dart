import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentTime;
  final String type;
  final MessageStatus status;

  const Message({
    required this.senderId,
    required this.receiverId,
    required this.sentTime,
    required this.content,
    this.type = 'text',
    this.status = MessageStatus.sending,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    receiverId: json['receiverId'] ?? '',
    senderId: json['senderId'] ?? '',
    sentTime: (json['sentTime'] as Timestamp).toDate(),
    content: json['content'] ?? '',
    type: json['type'] ?? 'text',
    // Safely handle null status
    status: json['status'] != null 
        ? MessageStatus.values[json['status'] as int] 
        : MessageStatus.sending,
  );

  Map<String, dynamic> toJson() => {
    'receiverId': receiverId,
    'senderId': senderId,
    'sentTime': sentTime,
    'content': content,
    'type': type,
    'status': status.index,
  };
}

enum MessageType {
  text,
  image;

  String toJson() => name;

  factory MessageType.fromJson(String json) =>
      values.byName(json);
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read
}
