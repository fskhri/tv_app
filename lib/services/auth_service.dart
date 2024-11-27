import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = 'http://192.168.0.109:3000';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static String? _cachedToken;

  // Login dan dapatkan token
  static Future<Map<String, dynamic>?> login(String username, String password) async {
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
        
        // Simpan token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, data['token']);
        await prefs.setString(userKey, json.encode(data['user']));
        
        // Update cached token
        _cachedToken = data['token'];
        
        print('Token saved: $_cachedToken'); // Debug log
        
        // Verifikasi penyimpanan
        final savedToken = prefs.getString(tokenKey);
        print('Token verified from SharedPreferences: $savedToken'); // Debug log

        return data;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Dapatkan token yang tersimpan
  static Future<String?> getToken() async {
    try {
      // Cek cache dulu
      if (_cachedToken != null) {
        print('Returning cached token: $_cachedToken');
        return _cachedToken;
      }

      // Jika tidak ada di cache, ambil dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(tokenKey);
      print('Token retrieved from SharedPreferences: $_cachedToken');
      return _cachedToken;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get auth headers untuk request
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      print('No token available for headers');
      throw Exception('Authentication required');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    print('Generated headers: $headers'); // Debug log
    return headers;
  }

  // Dapatkan data user
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(userKey);
    if (userStr == null) return null;
    return json.decode(userStr);
  }

  // Cek apakah user adalah admin
  static Future<bool> isAdmin() async {
    final userData = await getUserData();
    return userData?['role'] == 'admin';
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
    _cachedToken = null;
  }
}
