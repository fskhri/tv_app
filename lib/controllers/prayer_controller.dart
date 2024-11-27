import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import '../models/mosque_model.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../helpers/database_helper.dart';

class PrayerController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  PrayerController();

  Map<String, DateTime>? _todayPrayers;
  List<Map<String, dynamic>>? _monthlySchedule;
  String? _selectedProvince;
  String? _selectedCity;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Getter untuk waktu sholat
  DateTime? get imsak => _todayPrayers?['imsak'];
  DateTime? get subuh => _todayPrayers?['subuh'];
  DateTime? get terbit => _todayPrayers?['terbit'];
  DateTime? get dhuha => _todayPrayers?['dhuha'];
  DateTime? get dzuhur => _todayPrayers?['dzuhur'];
  DateTime? get ashar => _todayPrayers?['ashar'];
  DateTime? get maghrib => _todayPrayers?['maghrib'];
  DateTime? get isya => _todayPrayers?['isya'];

  // Method untuk mendapatkan daftar provinsi
  Future<List<Map<String, dynamic>>> getProvinces() async {
    final response = await http
        .get(Uri.parse('https://jadwalsholat-silk.vercel.app/api/provinsi'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception('Failed to load provinces');
  }

  // Method untuk mendapatkan daftar kota
  Future<List<Map<String, dynamic>>> getCities(String province) async {
    final response = await http.get(Uri.parse(
        'https://jadwalsholat-silk.vercel.app/api/kota?provinsi=$province'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception('Failed to load cities');
  }

  // Method untuk mendapatkan lokasi dan update jadwal sholat
  Future<void> updatePrayerTimesByGPS() async {
    try {
      // Set default location untuk testing (Jakarta)
      String province = 'dki jakarta';
      String city = 'kota jakarta';

      try {
        // Cek permission lokasi
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permission denied');
          }
        }

        // Dapatkan posisi
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // Dapatkan alamat dari koordinat
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          province =
              _formatProvinceName(place.administrativeArea ?? 'dki jakarta');
          city = _formatCityName(place.subAdministrativeArea ?? 'kota jakarta');
        }
      } catch (e) {
        print('Error getting location: $e');
        // Gunakan lokasi default jika gagal mendapatkan lokasi
      }

      // Update jadwal sholat dengan lokasi yang didapat atau default
      await updatePrayerTimes(province, city);
    } catch (e) {
      print('Error updating prayer times: $e');
      throw Exception('Failed to update prayer times');
    }
  }

  // Helper method untuk format nama provinsi
  String _formatProvinceName(String province) {
    // Konversi nama provinsi ke format yang sesuai dengan API
    // Contoh: "DKI JAKARTA" -> "dki jakarta"
    return province.toLowerCase();
  }

  // Helper method untuk format nama kota
  String _formatCityName(String city) {
    // Konversi nama kota ke format yang sesuai dengan API
    // Tambahkan "kota" atau "kabupaten" sesuai kebutuhan
    // Contoh: "JAKARTA PUSAT" -> "kota jakarta"
    if (city.toLowerCase().contains('jakarta')) {
      return 'kota jakarta';
    }
    return 'kota ${city.toLowerCase()}';
  }

  // Method untuk update jadwal sholat
  Future<void> updatePrayerTimes(String province, String city) async {
    _selectedProvince = province;
    _selectedCity = city;

    try {
      final now = DateTime.now();
      final response = await http.get(Uri.parse(
          'https://jadwalsholat-silk.vercel.app/api/cari?provinsi=$province&kota=$city&bulan=${now.month}&tahun=${now.year}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _monthlySchedule = List<Map<String, dynamic>>.from(data['data']);

        // Simpan ke database lokal
        await _dbHelper.savePrayerSchedules(_monthlySchedule!);

        _updateTodayPrayers();
        notifyListeners();
      } else {
        throw Exception('Failed to load prayer times');
      }
    } catch (e) {
      print('Error fetching online data: $e');
      // Jika gagal ambil data online, coba ambil dari database lokal
      try {
        _monthlySchedule = await _dbHelper.getPrayerSchedules();
        if (_monthlySchedule != null && _monthlySchedule!.isNotEmpty) {
          _updateTodayPrayers();
          notifyListeners();
        } else {
          throw Exception('No local data available');
        }
      } catch (localError) {
        print('Error fetching local data: $localError');
        throw Exception(
            'Failed to load prayer times from both online and local sources');
      }
    }
  }

  // Method untuk update jadwal hari ini
  void _updateTodayPrayers() {
    if (_monthlySchedule == null) return;

    final now = DateTime.now();
    final today = _monthlySchedule!.firstWhere(
      (schedule) => schedule['key'] == DateFormat('yyyy-MM-dd').format(now),
      orElse: () => _monthlySchedule!.first,
    );

    _todayPrayers = {
      'imsak': _parseTimeToDateTime(today['imsak']),
      'subuh': _parseTimeToDateTime(today['subuh']),
      'terbit': _parseTimeToDateTime(today['terbit']),
      'dhuha': _parseTimeToDateTime(today['dhuha']),
      'dzuhur': _parseTimeToDateTime(today['dzuhur']),
      'ashar': _parseTimeToDateTime(today['ashar']),
      'maghrib': _parseTimeToDateTime(today['maghrib']),
      'isya': _parseTimeToDateTime(today['isya']),
    };
  }

  // Helper method untuk parse waktu ke DateTime
  DateTime _parseTimeToDateTime(String timeStr, {int addDays = 0}) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day + addDays,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  // Method untuk mendapatkan waktu sholat berikutnya
  (DateTime?, String) getNextPrayer() {
    if (_todayPrayers == null) return (null, '');

    final now = DateTime.now();
    final prayers = {
      'Imsak': imsak,
      'Subuh': subuh,
      'Terbit': terbit,
      'Dhuha': dhuha,
      'Dzuhur': dzuhur,
      'Ashar': ashar,
      'Maghrib': maghrib,
      'Isya': isya,
    };

    DateTime? nextPrayer;
    String nextPrayerName = '';

    // Cari waktu sholat berikutnya hari ini
    prayers.forEach((name, time) {
      if (time != null && time.isAfter(now)) {
        if (nextPrayer == null || time.isBefore(nextPrayer!)) {
          nextPrayer = time;
          nextPrayerName = name;
        }
      }
    });

    // Jika tidak ada waktu sholat berikutnya hari ini, ambil jadwal besok
    if (nextPrayer == null && _monthlySchedule != null) {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final tomorrowKey = DateFormat('yyyy-MM-dd').format(tomorrow);

      // Cari jadwal untuk besok
      final tomorrowSchedule = _monthlySchedule!.firstWhere(
        (schedule) => schedule['key'] == tomorrowKey,
        orElse: () => _monthlySchedule!.first,
      );

      // Set waktu sholat pertama besok (Imsak)
      nextPrayer = _parseTimeToDateTime(tomorrowSchedule['imsak'], addDays: 1);
      nextPrayerName = 'Imsak';
    }

    return (nextPrayer, nextPrayerName);
  }

  // Method untuk mendapatkan countdown ke waktu sholat berikutnya
  Duration? getCountdown() {
    final (nextPrayer, _) = getNextPrayer();
    if (nextPrayer == null) return null;

    return nextPrayer.difference(DateTime.now());
  }

  // Method untuk format countdown yang lebih informatif
  String formatCountdown(Duration? duration) {
    if (duration == null) return '--:--:--';

    if (duration.inDays > 0) {
      return '${duration.inDays} hari ${(duration.inHours % 24).toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // Method untuk mendapatkan tanggal
  String getDate() {
    if (_monthlySchedule == null) return '';
    final now = DateTime.now();
    final today = _monthlySchedule!.firstWhere(
      (schedule) => schedule['key'] == DateFormat('yyyy-MM-dd').format(now),
      orElse: () => _monthlySchedule!.first,
    );
    return today['tanggal'];
  }

  Future<List<Map<String, dynamic>>> getPrayerSchedules(
      String province, String city, int month, int year) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://jadwalsholat-silk.vercel.app/api/cari?provinsi=$province&kota=$city&bulan=$month&tahun=$year'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return List<Map<String, dynamic>>.from(jsonResponse['data']);
      } else {
        throw Exception('Gagal mengambil jadwal sholat');
      }
    } catch (e) {
      print('Error fetching prayer schedules: $e');
      // Jika gagal, coba ambil dari database lokal
      try {
        return await _dbHelper.getPrayerSchedules();
      } catch (e) {
        print('Error fetching local data: $e');
        throw e;
      }
    }
  }
}
