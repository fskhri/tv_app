import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tv_app/models/user_location.dart';
import 'package:tv_app/models/prayer_schedule.dart';
import '../models/user.dart' as user_model;

class ApiService {
  static const String baseUrl = 'https://0g7d00kv-3000.asse.devtunnels.ms';
  static const String prayerApiUrl = 'https://jadwalsholat-silk.vercel.app/api';
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

        return usersData
            .map((userData) => user_model.User(
                  id: userData['id'].toString(),
                  username: userData['username'].toString(),
                  role: userData['role'].toString(),
                  isActive: userData['is_active'] == 1 ||
                      userData['isActive'] == true,
                ))
            .toList();
      }
      throw Exception('Failed to load users: ${response.body}');
    } catch (e) {
      print('Error getting users: $e');
      throw e;
    }
  }

  Future<user_model.User> createUser(
      String username, String password, String role) async {
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

  Future<List<PrayerSchedule>> getPrayerSchedules(
      String province, String city, int month, int year) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://jadwalsholat-silk.vercel.app/api/cari?provinsi=$province&kota=$city&bulan=$month&tahun=$year'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data
            .map((schedule) => PrayerSchedule.fromJson(schedule))
            .toList();
      } else {
        throw Exception('Gagal mengambil jadwal sholat');
      }
    } catch (e) {
      print('Error fetching prayer schedules: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      print('Attempting login for username: $username');

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
        _token = data['token'];
        print('Login successful, token received: $_token');
        return data;
      } else {
        final errorData = json.decode(response.body);
        print('Login failed: ${errorData['message']}');
        throw Exception(errorData['message']);
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
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

  Future<String> getUserId(String username) async {
    final url = '$baseUrl/api/user-locations/user-id/$username';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user_id'];
    } else {
      throw Exception('Failed to get user ID');
    }
  }

  Future<void> addUserLocation(
      String userId, String province, String city) async {
    try {
      print('Adding location for userId: $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/user-locations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _token != null ? 'Bearer $_token' : '',
        },
        body: jsonEncode({
          'user_id': userId,
          'province': province,
          'city': city,
        }),
      );

      print('Add response status: ${response.statusCode}');
      print('Add response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to add location');
      }
    } catch (e) {
      print('Error in addUserLocation: $e');
      throw Exception('Gagal menambahkan lokasi: $e');
    }
  }

  Future<List<UserLocation>> fetchUserLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-locations'),
        headers: _getHeaders(),
      );

      print(
          'Fetch locations response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserLocation.fromJson(json)).toList();
      }
      throw Exception('Failed to load user locations');
    } catch (e) {
      print('Error fetching user locations: $e');
      throw Exception('Gagal memuat daftar lokasi');
    }
  }

  Future<List<Map<String, String>>> getProvinces() async {
    try {
      final response = await http.get(Uri.parse('$prayerApiUrl/provinsi'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data
            .map((item) => {
                  'id': item['id'].toString(),
                  'name': item['name'].toString(),
                })
            .toList();
      }
      throw Exception('Failed to load provinces');
    } catch (e) {
      print('Error loading provinces: $e');
      throw Exception('Gagal memuat daftar provinsi');
    }
  }

  Future<List<Map<String, String>>> getCities(String provinceName) async {
    try {
      final encodedProvince = Uri.encodeComponent(provinceName.toLowerCase());
      final response = await http
          .get(Uri.parse('$prayerApiUrl/kota?provinsi=$encodedProvince'));

      print('Get cities response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data
            .map((city) => {
                  'id': city['id'].toString(),
                  'name': city['name'].toString(),
                })
            .toList();
      }
      throw Exception('Failed to load cities');
    } catch (e) {
      print('Error loading cities: $e');
      throw Exception('Gagal memuat daftar kota');
    }
  }

  Future<UserLocation?> getUserLocation(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-locations/user/$userId'),
        headers: _getHeaders(),
      );

      print('Get location response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return UserLocation.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get user location');
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }

  Future<void> saveUserLocation(
      String userId, String province, String city) async {
    try {
      final existingLocation = await getUserLocation(userId);
      final endpoint = existingLocation != null
          ? '$baseUrl/api/user-locations/$userId'
          : '$baseUrl/api/user-locations';

      final method = existingLocation != null ? http.put : http.post;

      final response = await method(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _token != null ? 'Bearer $_token' : '',
        },
        body: jsonEncode({
          if (existingLocation == null) 'user_id': userId,
          'province': province,
          'city': city,
        }),
      );

      print(
          'Save location response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save location');
      }
    } catch (e) {
      print('Error saving location: $e');
      throw Exception('Gagal menyimpan lokasi');
    }
  }
}
