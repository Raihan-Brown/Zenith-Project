class UserModel {
  final int id;
  final String name;
  final String nis; // Kita pakai NIS sebagai identitas utama
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
    // FUNGSI SAFETY: Biar gak error kalau backend ngirim angka sebagai string atau null
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
      id: parseIntSafe(json['id']),
      
      // Ambil nama, kalau kosong pakai 'User'
      name: parseStringSafe(json['name'], 'User Zenith'),
      
      // Backend kadang kirim 'username', kadang 'nis', kadang 'email'. Kita cek semua.
      nis: parseStringSafe(json['nis'] ?? json['username'] ?? json['email'], '-'),
      
      // Role dipaksa jadi huruf kecil biar logic 'admin' vs 'user' jalan
      role: parseStringSafe(json['role'], 'user').toLowerCase(),
      
      // Poin dipastikan jadi integer
      points: parseIntSafe(json['points'] ?? json['point']), 
      
      profilePhoto: json['profile_photo_url']?.toString(),
    );
  }
}