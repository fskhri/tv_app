class MosqueModel {
  final int? id;
  final String mosqueName;
  final double latitude;
  final double longitude;
  final String runningText;
  final bool enableAdzanSound;
  final bool enableIqamahSound;

  MosqueModel({
    this.id,
    required this.mosqueName,
    required this.latitude,
    required this.longitude,
    required this.runningText,
    required this.enableAdzanSound,
    required this.enableIqamahSound,
  });

  factory MosqueModel.fromMap(Map<String, dynamic> map) {
    return MosqueModel(
      id: map['id'],
      mosqueName: map['mosque_name'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      runningText: map['running_text'] ?? '',
      enableAdzanSound: map['enable_adzan_sound'] == 1,
      enableIqamahSound: map['enable_iqamah_sound'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mosque_name': mosqueName,
      'latitude': latitude,
      'longitude': longitude,
      'running_text': runningText,
      'enable_adzan_sound': enableAdzanSound ? 1 : 0,
      'enable_iqamah_sound': enableIqamahSound ? 1 : 0,
    };
  }
} 