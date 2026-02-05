class ReportModel {
  final int id;
  final String qrToken;
  final int points;
  final String status;
  final DateTime createdAt;
  final String userName;

  ReportModel({
    required this.id,
    required this.qrToken,
    required this.points,
    required this.status,
    required this.createdAt,
    required this.userName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Helper safety (selalu kita pakai biar anti-crash)
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ReportModel(
      id: parseIntSafe(json['id']),
      qrToken: json['qr_token']?.toString() ?? '-',
      points: parseIntSafe(json['points']),
      status: json['status']?.toString() ?? 'UNKNOWN',
      // Parsing tanggal dari backend
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      userName: json['user_name']?.toString() ?? 'Unknown User',
    );
  }
}