class LeaderboardModel {
  final String name;
  final int points;

  LeaderboardModel({required this.name, required this.points});

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      name: json['name']?.toString() ?? 'Unknown',
      points: int.tryParse(json['points'].toString()) ?? 0,
    );
  }
}