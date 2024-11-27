class UserLocation {
  final String userId;
  final String province;
  final String city;

  UserLocation({
    required this.userId,
    required this.province,
    required this.city,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['user_id'].toString(),
      province: json['province'].toString(),
      city: json['city'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'province': province,
      'city': city,
    };
  }
}
