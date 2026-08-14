import 'user_model.dart';

class LeaderboardEntry {
  final int rank, id, totalPoints, currentStreak, maxStreak;
  final String name, userCode;
  final String? avatarPath;
  final LevelInfo? level;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    required this.userCode,
    required this.totalPoints,
    required this.currentStreak,
    required this.maxStreak,
    this.avatarPath,
    this.level,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'] ?? 0,
        id: j['id'],
        name: j['name'] ?? '',
        userCode: j['user_code'] ?? '',
        totalPoints: j['total_points'] ?? 0,
        currentStreak: j['current_streak'] ?? 0,
        maxStreak: j['max_streak'] ?? 0,
        avatarPath: j['avatar_path'],
        level: j['level'] is Map ? LevelInfo.fromJson(j['level']) : null,
      );
}
