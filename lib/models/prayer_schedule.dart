class PrayerSchedule {
  final int id;
  final String prayerName;
  final String time;
  final String date;

  PrayerSchedule({
    required this.id,
    required this.prayerName, 
    required this.time,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prayer_name': prayerName,
      'time': time,
      'date': date,
    };
  }

  factory PrayerSchedule.fromMap(Map<String, dynamic> map) {
    return PrayerSchedule(
      id: map['id'],
      prayerName: map['prayer_name'],
      time: map['time'], 
      date: map['date'],
    );
  }
} 