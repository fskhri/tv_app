import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserRepository {
  final DatabaseService _databaseService;
  final SyncService _syncService;

  UserRepository(this._databaseService, this._syncService);

  // Hash password sebelum disimpan
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<List<UserModel>> getAllUsers() async {
    return await _databaseService.getAllUsers();
  }

  Future<UserModel?> createUser({
    required String username,
    required String password,
    required String role,
    String? mosqueId,
  }) async {
    final hashedPassword = _hashPassword(password);
    
    final user = UserModel(
      username: username,
      password: hashedPassword,
      role: role,
      mosqueId: mosqueId,
      createdAt: DateTime.now(),
    );

    final id = await _databaseService.createUser(user);
    await _syncService.markNeedsSync();
    
    return await _databaseService.getUserById(id);
  }

  Future<bool> updateUser(UserModel user, {String? newPassword}) async {
    if (newPassword != null) {
      user = UserModel(
        id: user.id,
        username: user.username,
        password: _hashPassword(newPassword),
        role: user.role,
        mosqueId: user.mosqueId,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );
    }

    final result = await _databaseService.updateUser(user);
    await _syncService.markNeedsSync();
    return result > 0;
  }

  Future<bool> deleteUser(int id) async {
    final result = await _databaseService.deleteUser(id);
    await _syncService.markNeedsSync();
    return result > 0;
  }

  Future<bool> validateCredentials(String username, String password) async {
    final db = await _databaseService.database;
    final hashedPassword = _hashPassword(password);
    
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    return result.isNotEmpty;
  }
} 