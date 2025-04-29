class Message {
  final int id;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final int userId;
  final int chatId;

  Message({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isRead,
    required this.userId,
    required this.chatId,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as int,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool,
        userId: json['user_id'] as int,
        chatId: json['chat_id'] as int,
      );

  Map<String, dynamic> toJson() => {
        'content': content,
      };
}