import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../controllers/auth_controller.dart';
import 'database_helper.dart';
import '../models/prayer_schedule.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';

class SyncService {
  final DatabaseService _databaseService;
  final AuthController _authController;
  final String baseUrl = 'https://localhost:3000'; // Ganti dengan URL admin panel Anda
  final dbHelper = DatabaseHelper.instance;

  SyncService(this._databaseService, this._authController);

  Future<void> syncWithServer() async {
    try {
      if (!await _hasInternetConnection()) return;
      if (!await _needsSync()) return;

      final token = await _authController.getToken();
      if (token == null) return;

      // Ambil data lokal
      final localPrayerTimes = await getLocalPrayerTimes();
      
      // Kirim ke server
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'prayerSchedules': localPrayerTimes.map((schedule) => schedule.toMap()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final serverData = json.decode(response.body);
        
        if (serverData['success']) {
          // Update database lokal dengan data dari server
          await dbHelper.deleteAllPrayerSchedules();
          
          for (var scheduleData in serverData['data']) {
            final schedule = PrayerSchedule.fromMap(scheduleData);
            await dbHelper.insertPrayerSchedule(schedule);
          }
          
          // Update status sync
          await _updateSyncStatus();
        }
      }
    } catch (e) {
      print('Sync error: $e');
      throw Exception('Sync failed: $e');
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://google.com'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _needsSync() async {
    final db = await _databaseService.database;
    final result = await db.query('sync_status');
    return result.isEmpty || result.first['needs_sync'] == 1;
  }

  Future<void> _updateSyncStatus() async {
    final db = await _databaseService.database;
    await db.insert(
      'sync_status',
      {
        'last_sync': DateTime.now().toIso8601String(),
        'needs_sync': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Panggil ini setiap kali ada perubahan lokal
  Future<void> markNeedsSync() async {
    final db = await _databaseService.database;
    await db.update(
      'sync_status',
      {'needs_sync': 1},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> syncPrayerTimes() async {
    try {
      // Coba ambil data dari API
      final onlineData = await fetchOnlinePrayerTimes();
      
      // Hapus data lama
      await dbHelper.deleteAllPrayerSchedules();
      
      // Simpan data baru ke database lokal
      for (var schedule in onlineData) {
        await dbHelper.insertPrayerSchedule(schedule);
      }
    } catch (e) {
      throw Exception('Failed to load prayer times from both online and local sources');
    }
  }

  Future<List<PrayerSchedule>> fetchOnlinePrayerTimes() async {
    try {
      // Contoh implementasi menggunakan package adhan yang sudah ada di dependencies
      final coordinates = await _getCurrentLocation();
      final params = CalculationMethod.karachi.getParameters();
      final prayerTimes = PrayerTimes.today(coordinates, params);
      
      return [
        PrayerSchedule(
          id: 1,
          prayerName: 'Fajr',
          time: DateFormat.Hm().format(prayerTimes.fajr),
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
        PrayerSchedule(
          id: 2,
          prayerName: 'Dhuhr',
          time: DateFormat.Hm().format(prayerTimes.dhuhr),
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
        PrayerSchedule(
          id: 3,
          prayerName: 'Asr',
          time: DateFormat.Hm().format(prayerTimes.asr),
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
        PrayerSchedule(
          id: 4,
          prayerName: 'Maghrib',
          time: DateFormat.Hm().format(prayerTimes.maghrib),
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
        PrayerSchedule(
          id: 5,
          prayerName: 'Isha',
          time: DateFormat.Hm().format(prayerTimes.isha),
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
      ];
    } catch (e) {
      print('Error fetching online prayer times: $e');
      // Kembalikan list kosong jika terjadi error
      return [];
    }
  }

  Future<Coordinates> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, return default location
          return Coordinates(-6.200000, 106.816666); // Jakarta coordinates
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        return Coordinates(-6.200000, 106.816666); // Jakarta coordinates
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      return Coordinates(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      // Default coordinates jika tidak bisa mendapatkan lokasi
      return Coordinates(-6.200000, 106.816666); // Jakarta coordinates
    }
  }

  Future<List<PrayerSchedule>> getLocalPrayerTimes() async {
    try {
      return await dbHelper.getAllPrayerSchedules();
    } catch (e) {
      throw Exception('Error fetching local data: $e');
    }
  }

  // Tambahkan method untuk mengambil data terbaru dari server
  Future<void> fetchLatestFromServer() async {
    try {
      if (!await _hasInternetConnection()) return;

      final token = await _authController.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/sync/latest'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final serverData = json.decode(response.body);
        
        if (serverData['success']) {
          await dbHelper.deleteAllPrayerSchedules();
          
          for (var scheduleData in serverData['data']) {
            final schedule = PrayerSchedule.fromMap(scheduleData);
            await dbHelper.insertPrayerSchedule(schedule);
          }
        }
      }
    } catch (e) {
      print('Error fetching latest data: $e');
      throw Exception('Failed to fetch latest data: $e');
    }
  }

  // Mengambil semua jadwal sholat
  Future<Map<String, List<PrayerSchedule>>> getAllPrayerSchedules() async {
    try {
      final token = await _authController.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/sync/list'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final schedules = Map<String, List<PrayerSchedule>>();
          
          (data['data'] as Map<String, dynamic>).forEach((date, scheduleList) {
            schedules[date] = (scheduleList as List)
                .map((schedule) => PrayerSchedule.fromMap(schedule))
                .toList();
          });
          
          return schedules;
        }
      }
      throw Exception('Failed to fetch prayer schedules');
    } catch (e) {
      print('Error getting prayer schedules: $e');
      throw Exception('Failed to load prayer schedules');
    }
  }

  // Mengambil jadwal sholat hari ini
  Future<List<PrayerSchedule>> getTodayPrayerSchedules() async {
    try {
      final token = await _authController.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/sync/today'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((schedule) => PrayerSchedule.fromMap(schedule))
              .toList();
        }
      }
      throw Exception('Failed to fetch today\'s prayer schedules');
    } catch (e) {
      print('Error getting today\'s prayer schedules: $e');
      throw Exception('Failed to load today\'s prayer schedules');
    }
  }

  // Mengambil jadwal sholat berdasarkan range tanggal
  Future<Map<String, List<PrayerSchedule>>> getPrayerSchedulesByRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final token = await _authController.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/sync/range').replace(queryParameters: {
          'startDate': DateFormat('yyyy-MM-dd').format(startDate),
          'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        }),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final schedules = Map<String, List<PrayerSchedule>>();
          
          (data['data'] as Map<String, dynamic>).forEach((date, scheduleList) {
            schedules[date] = (scheduleList as List)
                .map((schedule) => PrayerSchedule.fromMap(schedule))
                .toList();
          });
          
          return schedules;
        }
      }
      throw Exception('Failed to fetch prayer schedules for date range');
    } catch (e) {
      print('Error getting prayer schedules by range: $e');
      throw Exception('Failed to load prayer schedules for date range');
    }
  }

  Future<Map<String, dynamic>> getUserLocation() async {
    try {
      final token = await _authController.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/sync/user-location'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      throw Exception('Failed to fetch user location');
    } catch (e) {
      print('Error getting user location: $e');
      // Return default location
      return {
        'city': 'Jakarta Pusat',
        'province': 'DKI Jakarta'
      };
    }
  }

  Future<void> setUserLocation(String city, String province) async {
    try {
      final token = await _authController.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.post(
        Uri.parse('$baseUrl/sync/set-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'city': city,
          'province': province,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set user location');
      }
    } catch (e) {
      print('Error setting user location: $e');
      throw Exception('Failed to set user location');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableLocations() async {
    try {
      final token = await _authController.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl/sync/locations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Failed to fetch available locations');
    } catch (e) {
      print('Error getting available locations: $e');
      throw Exception('Failed to load available locations');
    }
  }

  Future<void> generateYearlySchedule() async {
    try {
      final token = await _authController.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.post(
        Uri.parse('$baseUrl/sync/generate-yearly-schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception(data['message']);
        }
        // Setelah generate berhasil, update data lokal
        await fetchLatestFromServer();
      } else {
        throw Exception('Failed to generate yearly schedule');
      }
    } catch (e) {
      print('Error generating yearly schedule: $e');
      throw Exception('Failed to generate yearly schedule: $e');
    }
  }
} 