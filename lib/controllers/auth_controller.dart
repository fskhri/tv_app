import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthController extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  late final ApiService _apiService;
  User? _currentUser;
  String? _token;

  AuthController() {
    _apiService = ApiService();
  }

  User? get currentUser => _currentUser;

  Future<void> init() async {
    await _loadSavedUser();
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    print('Token retrieved from SharedPreferences: $_token');
    return _token;
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      if (response != null) {
        final userData = response['user'] as Map<String, dynamic>;
        _currentUser = User(
          id: userData['id'] as String,
          username: userData['username'] as String,
          role: userData['role'] as String,
          isActive: userData['isActive'] == true,
        );
        
        _token = response['token'] as String;
        print('Token to be saved: $_token');
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        
        final savedToken = prefs.getString(_tokenKey);
        print('Token saved in SharedPreferences: $savedToken');
        
        await _saveUserData(_currentUser!);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userMap = {
      'id': user.id,
      'username': user.username,
      'role': user.role,
      'isActive': user.isActive,
    };
    await prefs.setString(_userKey, jsonEncode(userMap));
  }

  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);
      
      print('Loading saved data - Token: $token, UserData: $userData');

      if (userData != null && token != null) {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _currentUser = User(
          id: userMap['id'] as String,
          username: userMap['username'] as String,
          role: userMap['role'] as String,
          isActive: userMap['isActive'] as bool,
        );
        _token = token;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved user: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && _currentUser != null;
  }

  Future<bool> isAdmin() async {
    await _loadSavedUser();
    return _currentUser?.role == 'admin';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _currentUser = null;
    _token = null;
    notifyListeners();
  }
}
