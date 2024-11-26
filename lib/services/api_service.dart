import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tv_app/models/prayer_schedule.dart';
import '../models/user.dart' as user_model;
import '../controllers/auth_controller.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.109:3000';
  final AuthController _authController;

  ApiService(this._authController);

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded data: $data');
        return {
          'token': data['token'],
          'user': data['user'],
        };
      }
      return null;
    } catch (e) {
      print('API Error: $e');
      return null;
    }
  }

  // Helper method untuk mendapatkan headers dengan token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authController.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<user_model.User>> getUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );
      
      print('Get users response: ${response.body}');
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => user_model.User.fromMap(json)).toList();
      }
      throw Exception('Failed to load users: ${response.body}');
    } catch (e) {
      print('Error getting users: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<user_model.User> createUser(user_model.User user, String password) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: headers,
        body: json.encode({
          'username': user.username,
          'password': password,
          'role': user.role,
        }),
      );
      
      print('Create user response: ${response.body}');
      
      if (response.statusCode == 201) {
        return user_model.User.fromMap(json.decode(response.body));
      }
      throw Exception('Failed to create user: ${response.body}');
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  Future<user_model.User> updateUser(user_model.User user) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: headers,
        body: json.encode(user.toMap()),
      );
      
      if (response.statusCode == 200) {
        return user_model.User.fromMap(json.decode(response.body));
      }
      throw Exception('Failed to update user: ${response.body}');
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
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
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/prayer-schedules'),
        headers: headers,
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
}
