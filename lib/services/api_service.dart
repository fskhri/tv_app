import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tv_app/models/user_location.dart';
import 'package:tv_app/models/prayer_schedule.dart';
import '../models/user.dart' as user_model;

class ApiService {
  static const String baseUrl = 'https://0g7d00kv-3000.asse.devtunnels.ms';
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
      if (_token == null) throw Exception('No token available');

      print('Attempting to add/update location for userId: $userId');
      print('Province: $province, City: $city');

      // Cek dulu apakah user sudah punya lokasi
      final checkResponse = await http.get(
        Uri.parse('$baseUrl/user-locations/check/$userId'),
        headers: _getHeaders(),
      );

      print('Check existing location response: ${checkResponse.statusCode}');
      print('Check response body: ${checkResponse.body}');

      if (checkResponse.statusCode == 200) {
        // User sudah punya lokasi, lakukan update
        print('User location exists, performing update');
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/user-locations/$userId'),
          headers: _getHeaders(),
          body: json.encode({
            'province': province,
            'city': city,
          }),
        );

        print('Update response status: ${updateResponse.statusCode}');
        print('Update response body: ${updateResponse.body}');

        if (updateResponse.statusCode != 200) {
          throw Exception('Failed to update location: ${updateResponse.body}');
        }
      } else {
        // User belum punya lokasi, buat baru
        print('User location does not exist, creating new');
        final createResponse = await http.post(
          Uri.parse('$baseUrl/user-locations'),
          headers: _getHeaders(),
          body: json.encode({
            'user_id': userId,
            'province': province,
            'city': city,
          }),
        );

        print('Create response status: ${createResponse.statusCode}');
        print('Create response body: ${createResponse.body}');

        if (createResponse.statusCode != 201) {
          throw Exception('Failed to create location: ${createResponse.body}');
        }
      }
    } catch (e) {
      print('Error in addUserLocation: $e');
      throw Exception('Failed to add/update user location: $e');
    }
  }

  Future<List<UserLocation>> fetchUserLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-locations'),
        headers: _getHeaders(),
      );

      print('Fetch response status: ${response.statusCode}');
      print('Fetch response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> locationsData = json.decode(response.body);
        return locationsData
            .map((data) => UserLocation.fromJson(data))
            .toList();
      } else {
        throw Exception('Failed to load user locations');
      }
    } catch (e) {
      print('Error fetching user locations: $e');
      throw e;
    }
  }

  Future<List<Map<String, String>>> getProvinces() async {
    final response = await http
        .get(Uri.parse('https://jadwalsholat-silk.vercel.app/api/provinsi'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data
          .map((item) =>
              {'id': item['id'].toString(), 'name': item['name'].toString()})
          .toList();
    }
    throw Exception('Failed to load provinces');
  }

  Future<List<Map<String, String>>> getCities(String provinceId) async {
    try {
      print('Fetching cities for province ID: $provinceId');
      
      // Encode parameter provinsi untuk URL
      final encodedProvinceId = Uri.encodeComponent(provinceId.toLowerCase());
      final url = 'https://jadwalsholat-silk.vercel.app/api/kota?provinsi=$encodedProvinceId';
      
      print('Request URL: $url');
      final response = await http.get(Uri.parse(url));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((city) => {
          'id': city['id'].toString(),
          'name': city['name'].toString(),
        }).toList();
      }
      throw Exception('Failed to load cities');
    } catch (e) {
      print('Error loading cities: $e');
      throw Exception('Failed to load cities');
    }
  }

  Future<List<UserLocation>> getUserLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-locations'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => UserLocation.fromJson(data)).toList();
      } else {
        throw Exception('Gagal mengambil data lokasi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateUserLocation(
      String userId, String province, String city) async {
    try {
      print('Updating location for userId: $userId');
      print('Data: province=$province, city=$city');

      // Hanya kirim data yang diperlukan
      final requestBody = {
        'userId': userId,
        'province': province,
        'city': city,
      };

      print('Request body: $requestBody'); // Tambah logging

      final response = await http.post(
        Uri.parse('$baseUrl/user-locations/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _token != null ? 'Bearer $_token' : '',
        },
        body: jsonEncode(requestBody), // Gunakan requestBody yang sudah dibuat
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
              errorData['message'] ?? 'Gagal memperbarui lokasi pengguna');
        } catch (e) {
          throw Exception(
              'Gagal memperbarui lokasi pengguna: Status ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception(data['message'] ?? 'Gagal memperbarui lokasi pengguna');
      }
    } catch (e) {
      print('Error in updateUserLocation: $e');
      rethrow;
    }
  }
}
