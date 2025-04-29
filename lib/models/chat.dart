class Chat {
  final int id;
  final String name;
  final DateTime createdAt;
  final bool isGroupChat;

  Chat({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.isGroupChat,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'] as int,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isGroupChat: json['is_group_chat'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'is_group_chat': isGroupChat,
      };
}