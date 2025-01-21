class Message {
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentTime;
  final String type;

  const Message({
    required this.senderId,
    required this.receiverId,
    required this.sentTime,
    required this.content,
    this.type = 'text',
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(
        receiverId: json['receiverId'],
        senderId: json['senderId'],
        sentTime: json['sentTime'].toDate(),
        content: json['content'],
        type: json['type'] ?? 'text',
      );

  Map<String, dynamic> toJson() => {
        'receiverId': receiverId,
        'senderId': senderId,
        'sentTime': sentTime,
        'content': content,
        'type': type,
      };
}

enum MessageType {
  text,
  image;

  String toJson() => name;

  factory MessageType.fromJson(String json) =>
      values.byName(json);
}
