class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.gender,
    required this.age,
    required this.location,
    required this.homeLat,
    required this.homeLng,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String uid;
  final String fullName;
  final String gender; // 'male' | 'female' | 'other' | 'prefer_not_to_say'
  final int age;
  final String location;
  final double? homeLat;
  final double? homeLng;
  final String email;
  final String phone;
  final String photoUrl;
  final int createdAtMs;
  final int updatedAtMs;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'fullName': fullName,
        'gender': gender,
        'age': age,
        'location': location,
        'homeLat': homeLat,
        'homeLng': homeLng,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'createdAtMs': createdAtMs,
        'updatedAtMs': updatedAtMs,
      };

  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      gender: (json['gender'] as String?) ?? 'prefer_not_to_say',
      age: (json['age'] as num?)?.toInt() ?? 0,
      location: (json['location'] as String?) ?? '',
      homeLat: (json['homeLat'] as num?)?.toDouble(),
      homeLng: (json['homeLng'] as num?)?.toDouble(),
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      photoUrl: (json['photoUrl'] as String?) ?? '',
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (json['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

