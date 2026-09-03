class LevelInfo {
  final int level;
  final String name, titleAr, titleEn;
  final int rank;
  final int? nextAt;
  final int pointsToNext;
  final double progress;

  LevelInfo({
    required this.level,
    this.name = '',
    required this.titleAr,
    required this.titleEn,
    int? rank,
    this.nextAt,
    this.pointsToNext = 0,
    this.progress = 0,
  }) : rank = rank ?? level;

  factory LevelInfo.fromJson(Map<String, dynamic> j) => LevelInfo(
    // 'id' is the current field name; 'level' is kept as a fallback for
    // backward compatibility with any cached/older response shape.
    level: j['id'] ?? j['level'] ?? 1,
    name: j['name'] ?? '',
    titleAr: j['title_ar'] ?? '',
    titleEn: j['title_en'] ?? '',
    rank: j['rank'],
    nextAt: j['next_at'],
    pointsToNext: j['points_to_next'] ?? 0,
    progress: (j['progress'] ?? 0).toDouble(),
  );

  /// Localized flat name, preferring the server-provided [name] and falling
  /// back to picking the right bilingual title for older cached payloads.
  String displayName(bool isAr) => name.isNotEmpty ? name : (isAr ? titleAr : titleEn);

  /// The level's frame asset, resolved entirely on-device from the bundled
  /// `assets/frames/` folder — the backend only ever tells us *which* level
  /// a user is on, never a file path, so this stays correct even against a
  /// stale cached user object (the numeric level id has always been present).
  String get frame => 'assets/frames/frame_$level.png';
}

class UserModel {
  final int id;
  final String name, email, userCode;
  final int age, totalPoints, score, lastScore, bestScore, currentStreak, maxStreak;
  /// 'male' | 'female' | null (not set yet). Drives Arabic agreement.
  final String? gender;
  final double? lat, lng;
  final String? avatarPath;
  final LevelInfo? level;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userCode,
    required this.age,
    this.gender,
    required this.totalPoints,
    required this.score,
    required this.lastScore,
    required this.bestScore,
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
    gender: j['gender'],
    totalPoints: j['total_points'] ?? 0,
    score: j['score'] ?? 0,
    lastScore: j['last_score'] ?? 0,
    bestScore: j['best_score'] ?? 0,
    currentStreak: j['current_streak'] ?? 0,
    maxStreak: j['max_streak'] ?? 0,
    lat: double.tryParse(j['lat']?.toString() ?? ''),
    lng: double.tryParse(j['lng']?.toString() ?? ''),
    avatarPath: j['avatar_url'],
    level: j['level'] is Map ? LevelInfo.fromJson(j['level']) : null,
  );
}
