class PrayerSchedule {
  final String key;
  final String tanggal;
  final String imsak;
  final String subuh;
  final String terbit;
  final String dhuha;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  PrayerSchedule({
    required this.key,
    required this.tanggal,
    required this.imsak,
    required this.subuh,
    required this.terbit,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  // Getter untuk UI
  String get date => tanggal;
  String get time {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour < 5) return imsak;
    if (hour < 6) return subuh;
    if (hour < 12) return dzuhur;
    if (hour < 15) return ashar;
    if (hour < 18) return maghrib;
    return isya;
  }

  String get prayerName {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour < 5) return 'Imsak';
    if (hour < 6) return 'Subuh';
    if (hour < 12) return 'Dzuhur';
    if (hour < 15) return 'Ashar';
    if (hour < 18) return 'Maghrib';
    return 'Isya';
  }

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    return PrayerSchedule(
      key: json['key'],
      tanggal: json['tanggal'],
      imsak: json['imsak'],
      subuh: json['subuh'],
      terbit: json['terbit'],
      dhuha: json['dhuha'],
      dzuhur: json['dzuhur'],
      ashar: json['ashar'],
      maghrib: json['maghrib'],
      isya: json['isya'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'tanggal': tanggal,
      'imsak': imsak,
      'subuh': subuh,
      'terbit': terbit,
      'dhuha': dhuha,
      'dzuhur': dzuhur,
      'ashar': ashar,
      'maghrib': maghrib,
      'isya': isya,
    };
  }

  // Alias untuk kompatibilitas
  Map<String, dynamic> toMap() => toJson();
  static PrayerSchedule fromMap(Map<String, dynamic> map) => PrayerSchedule.fromJson(map);
} 