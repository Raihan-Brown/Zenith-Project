class UserModel {
  final String id; // [FIX] Ubah dari int ke String
  final String name;
  final String nis;
  final String role;
  final int points;
  final String? profilePhoto;

  UserModel({
    required this.id,
    required this.name,
    required this.nis,
    required this.role,
    required this.points,
    this.profilePhoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    String parseStringSafe(dynamic value, String defaultVal) {
      if (value == null) return defaultVal;
      return value.toString();
    }

    return UserModel(
      // [FIX] ID sekarang diambil sebagai String
      id: parseStringSafe(json['id'], ''), 
      name: parseStringSafe(json['name'], 'User Zenith'),
      nis: parseStringSafe(json['nis'] ?? json['username'] ?? json['email'], '-'),
      role: parseStringSafe(json['role'], 'user').toLowerCase(),
      points: parseIntSafe(json['points'] ?? json['point']), 
      profilePhoto: json['profile_photo_url']?.toString(),
    );
  }
}