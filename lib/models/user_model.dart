class UserModel {
  final int? id;
  final String username;
  final String? password; // Hanya digunakan saat create/update
  final String role; // 'admin' atau 'user'
  final String? mosqueId; // ID masjid yang dikelola user
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.username,
    this.password,
    required this.role,
    this.mosqueId,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      role: map['role'],
      mosqueId: map['mosque_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'mosque_id': mosqueId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 