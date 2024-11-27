import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tv_app/models/prayer_schedule.dart';
import '../models/user.dart' as user_model;

class ApiService {
  static const String baseUrl = 'http://192.168.0.109:3000';
  String? _token;

  void setToken(String token) {
    _token = token;
    print('Token set in ApiService: $_token');
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': _token != null ? 'Bearer $_token' : '',
    };
  }

  Future<List<user_model.User>> getUsers() async {
    try {
      if (_token == null) {
        throw Exception('No token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
      );

      print('Get users response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> usersData = json.decode(response.body);
        
        return usersData.map((userData) => user_model.User(
          id: userData['id'].toString(),
          username: userData['username'].toString(),
          role: userData['role'].toString(),
          isActive: userData['is_active'] == 1 || userData['isActive'] == true,
        )).toList();
      }
      throw Exception('Failed to load users: ${response.body}');
    } catch (e) {
      print('Error getting users: $e');
      throw e;
    }
  }

  Future<user_model.User> createUser(String username, String password, String role) async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
        body: json.encode({
          'username': username,
          'password': password,
          'role': role,
          'is_active': true,
        }),
      );

      if (response.statusCode == 201) {
        final userData = json.decode(response.body);
        return user_model.User(
          id: userData['id'].toString(),
          username: userData['username'],
          role: userData['role'],
          isActive: true,
        );
      }
      throw Exception('Failed to create user: ${response.body}');
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/status'),
        headers: _getHeaders(),
        body: json.encode({
          'is_active': isActive,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user status: ${response.body}');
      }
    } catch (e) {
      print('Error updating user status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<List<PrayerSchedule>> getPrayerSchedules() async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/prayer-schedules'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        return data.map((item) => PrayerSchedule.fromMap(item)).toList();
      }
      throw Exception('Gagal mengambil jadwal sholat');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token']; // Simpan token
        return data;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> updateUser(user_model.User user) async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: _getHeaders(),
        body: json.encode(user.toMap()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }
}
