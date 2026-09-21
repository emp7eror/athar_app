class LevelInfo {
  final int level;
  final String name, titleAr, titleEn;
  final int rank;
  final int? nextAt;
  final int pointsToNext;
  final double progress;

  /// Artwork for levels added after this build shipped. Null for the levels
  /// whose frames are bundled — see [frame].
  final String? frameUrl;

  LevelInfo({
    required this.level,
    this.name = '',
    required this.titleAr,
    required this.titleEn,
    int? rank,
    this.nextAt,
    this.pointsToNext = 0,
    this.progress = 0,
    this.frameUrl,
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
    frameUrl: (j['frame_url'] as String?)?.trim(),
  );

  /// The level's title in the reading language. [titleAr] arrives already
  /// agreeing with the user's gender, so it is preferred; [name] is the
  /// server's own locale pick and covers a payload that carries only that.
  String displayName(bool isAr) {
    final title = isAr ? titleAr : titleEn;
    return title.isNotEmpty ? title : name;
  }

  /// The level's bundled frame asset. Levels 1-5 shipped with the app, so
  /// these render offline and instantly, and stay correct even against a
  /// stale cached user object.
  ///
  /// A level added on the server later has no asset here; it carries
  /// [frameUrl] instead, which [FramedAvatar] prefers when present. Nothing
  /// breaks if neither resolves — the avatar simply appears unframed.
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
