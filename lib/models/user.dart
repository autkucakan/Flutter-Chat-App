class User {
  final int id;
  final String username;
  final String email;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final String? token; //jwt token

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.lastSeen,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSeen:
          json['last_seen'] != null
              ? DateTime.parse(json['last_seen'] as String)
              : null,
      token: json.containsKey('token') ? json['token'] as String : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (lastSeen != null) 'last_seen': lastSeen!.toUtc().toIso8601String(),
      if (token != null) 'token': token,
    };
  }
}
