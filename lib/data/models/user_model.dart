class LevelInfo {
  final int level;
  final String titleAr, titleEn;
  final int? nextAt;
  final int pointsToNext;
  final double progress;

  LevelInfo({
    required this.level,
    required this.titleAr,
    required this.titleEn,
    this.nextAt,
    this.pointsToNext = 0,
    this.progress = 0,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> j) => LevelInfo(
        level: j['level'] ?? 1,
        titleAr: j['title_ar'] ?? '',
        titleEn: j['title_en'] ?? '',
        nextAt: j['next_at'],
        pointsToNext: j['points_to_next'] ?? 0,
        progress: (j['progress'] ?? 0).toDouble(),
      );
}

class UserModel {
  final int id;
  final String name, email, userCode;
  final int age, totalPoints, currentStreak, maxStreak;
  final double? lat, lng;
  final String? avatarPath;
  final LevelInfo? level;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userCode,
    required this.age,
    required this.totalPoints,
    required this.currentStreak,
    required this.maxStreak,
    this.lat,
    this.lng,
    this.avatarPath,
    this.level,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        userCode: j['user_code'] ?? '',
        age: j['age'] ?? 0,
        totalPoints: j['total_points'] ?? 0,
        currentStreak: j['current_streak'] ?? 0,
        maxStreak: j['max_streak'] ?? 0,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        avatarPath: j['avatar_path'],
        level: j['level'] is Map ? LevelInfo.fromJson(j['level']) : null,
      );
}
