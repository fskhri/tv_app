class User {
  final String id;
  final String username;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final String? runningText;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.runningText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'running_text': runningText,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      username: map['username'] as String,
      role: map['role'] as String,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      runningText: map['running_text'] as String?,
    );
  }

  factory User.create({
    required String username,
    String role = 'user',
  }) {
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      runningText: null,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    String? runningText,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      runningText: runningText ?? this.runningText,
    );
  }
}
