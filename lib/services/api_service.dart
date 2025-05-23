import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tv_app/models/user_location.dart';
import 'package:tv_app/models/prayer_schedule.dart';
import '../models/user.dart' as user_model;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'https://0g7d00kv-3000.asse.devtunnels.ms';
  static const String prayerApiUrl = 'https://jadwalsholat-silk.vercel.app/api';
  String? _token;
  Dio _dio = Dio();

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
        Uri.parse('$baseUrl/user-locations'),
        headers: _getHeaders(),
      );

      print('Fetch response status: ${response.statusCode}');
      print('Fetch response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> locationsData = json.decode(response.body);
        return locationsData
            .map((data) => UserLocation.fromJson(data))
            .toList();
      }
      throw Exception('Failed to load user locations');
    } catch (e) {
      print('Error fetching user locations: $e');
      throw e;
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
      print('Checking existing location for userId: $userId');

      // Cek dulu apakah lokasi sudah ada di database
      final response = await http.get(
        Uri.parse('$baseUrl/user-locations/check/$userId'),
        headers: _getHeaders(),
      );

      print('Check response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Lokasi sudah ada, lakukan update
        print('Updating existing location for userId: $userId');
        final updateResponse = await http.post(
          Uri.parse('$baseUrl/user-locations/update'),
          headers: _getHeaders(),
          body: jsonEncode({
            'user_id': userId,
            'province': province,
            'city': city,
          }),
        );

        print(
            'Update response: ${updateResponse.statusCode} - ${updateResponse.body}');

        if (updateResponse.statusCode != 200) {
          throw Exception('Failed to update location');
        }
      } else if (response.statusCode == 404) {
        // Lokasi belum ada, buat baru
        print('Creating new location for userId: $userId');
        final createResponse = await http.post(
          Uri.parse('$baseUrl/user-locations'),
          headers: _getHeaders(),
          body: jsonEncode({
            'user_id': userId,
            'province': province,
            'city': city,
          }),
        );

        print(
            'Create response: ${createResponse.statusCode} - ${createResponse.body}');

        if (createResponse.statusCode != 201) {
          throw Exception('Failed to create location');
        }
      } else {
        throw Exception('Failed to check existing location');
      }
    } catch (e) {
      print('Error saving location: $e');
      throw Exception('Gagal menyimpan lokasi: $e');
    }
  }

  Future<void> uploadContent(
    String userId,
    String title,
    String description,
    List<File> images,
  ) async {
    try {
      print('Memulai upload konten untuk userId: $userId');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/content'),
      );

      // Tambahkan Authorization header
      request.headers['Authorization'] = 'Bearer $_token';

      // Tambahkan fields
      request.fields['userId'] = userId;
      request.fields['title'] = title;
      request.fields['description'] = description;

      // Upload gambar
      for (var i = 0; i < images.length; i++) {
        var file = images[i];
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();

        var multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: path.basename(file.path),
          contentType:
              MediaType('image', 'jpeg'), // Explicitly set content type
        );

        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception('Gagal mengupload konten: $responseData');
      }

      print('Upload berhasil: $responseData');
    } catch (e) {
      print('Error dalam proses upload: $e');
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserContents(String userId) async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/content/$userId'),
        headers: _getHeaders(),
      );

      print('Get contents response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
        throw Exception('Failed to get contents: ${jsonResponse['message']}');
      }
      throw Exception('Failed to get contents: ${response.body}');
    } catch (e) {
      print('Error getting contents: $e');
      throw Exception('Error getting contents: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllContents() async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/content'),
        headers: _getHeaders(),
      );

      print(
          'Get all contents response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final contents =
              List<Map<String, dynamic>>.from(jsonResponse['data']);

          // Pastikan URL gambar menggunakan baseUrl yang benar
          return contents.map((content) {
            if (content['image_urls_full'] != null) {
              content['image_urls_full'] =
                  (content['image_urls_full'] as List).map((url) {
                if (url.contains('localhost')) {
                  return url.replaceFirst('http://localhost:3000', baseUrl);
                }
                return url;
              }).toList();
            }
            return content;
          }).toList();
        }
        throw Exception('Failed to get contents: ${jsonResponse['message']}');
      }
      throw Exception('Failed to get contents: ${response.body}');
    } catch (e) {
      print('Error getting contents: $e');
      throw Exception('Error getting contents: $e');
    }
  }

  Future<Map<String, dynamic>> uploadContentFile({
    required File contentFile,
    required String title,
    required String description,
  }) async {
    try {
      final uri = Uri.parse('${baseUrl}/content/upload');

      var request = http.MultipartRequest('POST', uri);

      // Tambahkan file ke request
      var multipartFile =
          await http.MultipartFile.fromPath('content', contentFile.path);
      request.files.add(multipartFile);

      // Tambahkan data lainnya
      request.fields['title'] = title;
      request.fields['description'] = description;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return json.decode(responseData);
      } else {
        throw Exception('Gagal mengupload gambar');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUploadedImages(String userId) async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('${baseUrl}/content/images/$userId'),
        headers: _getHeaders(),
      );

      print('Get images response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
        throw Exception('Failed to get images: ${jsonResponse['message']}');
      }
      throw Exception('Failed to get images: ${response.body}');
    } catch (e) {
      print('Error getting images: $e');
      throw Exception('Error getting images: $e');
    }
  }

  Future<void> deleteImage(String imageId) async {
    try {
      if (_token == null) throw Exception('No token available');

      final response = await http.delete(
        Uri.parse('$baseUrl/content/images/$imageId'),
        headers: _getHeaders(),
      );

      print('Delete image response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menghapus gambar');
      }
    } catch (e) {
      print('Error deleting image: $e');
      throw Exception('Error menghapus gambar: $e');
    }
  }

  Future<String> getRunningText(String userId) async {
    try {
      final response = await _dio.get('/running-text/$userId');
      if (response.statusCode == 200) {
        return response.data['running_text'] as String;
      }
      throw Exception('Gagal mengambil running text');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update Running Text (Khusus Admin)
  Future<bool> updateRunningText(String userId, String newText) async {
    try {
      print('=== UPDATE RUNNING TEXT START ===');
      print('User ID: $userId');
      print('New Text: $newText');
      print('Token: ${_token?.substring(0, 10)}...');

      if (_token == null) {
        print('Error: Token not available');
        throw Exception('No token available');
      }

      print('Sending request to: $baseUrl/running-text');
      print('Headers: ${_getHeaders()}');
      print('Request body: ${json.encode({
            'running_text': newText,
            'userId': userId,
          })}');

      final response = await http.post(
        Uri.parse('$baseUrl/running-text'),
        headers: _getHeaders(),
        body: json.encode({
          'running_text': newText,
          'userId': userId,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Update successful');
        return true;
      } else {
        print('Update failed with status: ${response.statusCode}');
        final errorData = json.decode(response.body);
        print('Error data: $errorData');
        throw Exception(
            errorData['message'] ?? 'Gagal mengupdate running text');
      }
    } catch (e) {
      print('=== ERROR UPDATING RUNNING TEXT ===');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Error updating running text: $e');
    } finally {
      print('=== UPDATE RUNNING TEXT END ===');
    }
  }
}
