class HistoryModel {
  final int id;
  final String trashType;
  final int pointsEarned;
  final DateTime timestamp;
  final String deviceId;

  HistoryModel({
    required this.id,
    required this.trashType,
    required this.pointsEarned,
    required this.timestamp,
    required this.deviceId,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    // Helper safety (sama kayak di UserModel)
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return HistoryModel(
      id: parseIntSafe(json['id']),
      trashType: json['trash_type']?.toString() ?? 'Unknown',
      pointsEarned: parseIntSafe(json['points_earned']),
      // Parsing string ISO 8601 ke DateTime Dart
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      deviceId: json['device_id']?.toString() ?? '-',
    );
  }
}