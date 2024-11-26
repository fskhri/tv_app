class User {
  final String id;
  final String username;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'isActive': isActive,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      role: map['role'] as String,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
    );
  }
} 