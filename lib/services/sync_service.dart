import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/prayer_schedule.dart';
import '../services/database_service.dart';
import '../controllers/auth_controller.dart';

class SyncService {
  final DatabaseService _databaseService;
  final AuthController _authController;

  SyncService(this._databaseService, this._authController);

  Future<List<PrayerSchedule>> getPrayerTimes(String province, String city) async {
    try {
      final now = DateTime.now();
      final response = await http.get(
        Uri.parse(
          'https://jadwalsholat-silk.vercel.app/api/cari?provinsi=$province&kota=$city&bulan=${now.month}&tahun=${now.year}'
        )
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((schedule) => PrayerSchedule.fromJson(schedule)).toList();
      } else {
        throw Exception('Gagal mengambil jadwal sholat');
      }
    } catch (e) {
      print('Error getting prayer times: $e');
      throw e;
    }
  }

  Future<List<PrayerSchedule>> getTodayPrayerSchedules() async {
    return getPrayerTimes('dki jakarta', 'kota jakarta'); // Default location
  }

  Future<Map<String, String>> getUserLocation() async {
    // Return default location
    return {
      'province': 'dki jakarta',
      'city': 'kota jakarta'
    };
  }

  Future<List<Map<String, String>>> getAvailableLocations() async {
    try {
      final response = await http.get(
        Uri.parse('https://jadwalsholat-silk.vercel.app/api/provinsi')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return List<Map<String, String>>.from(
          data.map((loc) => {
            'province': loc['name'].toString().toLowerCase(),
            'city': 'kota ${loc['name'].toString().toLowerCase()}'
          })
        );
      } else {
        throw Exception('Gagal mengambil daftar lokasi');
      }
    } catch (e) {
      print('Error getting locations: $e');
      throw e;
    }
  }

  Future<void> setUserLocation(String province, String city) async {
    // Simpan lokasi ke preferences atau database jika diperlukan
    print('Setting location to: $province, $city');
  }

  Future<void> syncWithServer() async {
    try {
      final location = await getUserLocation();
      await getPrayerTimes(location['province']!, location['city']!);
    } catch (e) {
      print('Error syncing with server: $e');
      throw e;
    }
  }

  Future<void> markNeedsSync() async {
    // Implement if needed
    print('Marked for sync');
  }
}
