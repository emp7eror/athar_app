import 'user_model.dart';

/// One entry of a friend's today prayer checklist — used to render the small
/// per-prayer tick/cross row on the Friends page.
class PrayerCheckItem {
  final String prayerName;
  final bool isCompleted;
  final bool isOnTime;

  PrayerCheckItem({required this.prayerName, required this.isCompleted, required this.isOnTime});

  factory PrayerCheckItem.fromJson(Map<String, dynamic> j) => PrayerCheckItem(
        prayerName: j['prayer_name'] ?? '',
        isCompleted: j['is_completed'] == true,
    isOnTime: j['is_on_time'] == true,
      );
}

class FriendModel {
  final int id;
  final String name, userCode;
  final String? avatarPath, avatarUrl;
  final int totalPoints, score, currentStreak, todayPoints;
  final double todayProgress;
  final LevelInfo? level;
  final List<PrayerCheckItem> todayChecklist;

  FriendModel({
    required this.id,
    required this.name,
    required this.userCode,
    this.avatarPath,
    this.avatarUrl,
    this.totalPoints = 0,
    this.score = 0,
    this.currentStreak = 0,
    this.todayPoints = 0,
    this.todayProgress = 0,
    this.level,
    this.todayChecklist = const [],
  });

  factory FriendModel.fromJson(Map<String, dynamic> j) => FriendModel(
        id: j['id'],
        name: j['name'] ?? '',
        userCode: j['user_code'] ?? '',
        avatarPath: j['avatar_url'],
        avatarUrl: j['avatar_url'],
        totalPoints: j['total_points'] ?? 0,
        score: j['score'] ?? 0,
        currentStreak: j['current_streak'] ?? 0,
        todayPoints: j['today_points'] ?? 0,
        todayProgress: (j['today_progress'] ?? 0).toDouble(),
        level: j['level'] is Map ? LevelInfo.fromJson(j['level']) : null,
        todayChecklist: j['today_checklist'] is List
            ? (j['today_checklist'] as List)
                .map((e) => PrayerCheckItem.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
      );
}

class PendingRequest {
  final int friendshipId, id;
  final String name, userCode;
  final String? avatarPath, avatarUrl;
  final LevelInfo? level;

  PendingRequest({
    required this.friendshipId,
    required this.id,
    required this.name,
    required this.userCode,
    this.avatarPath,
    this.avatarUrl,
    this.level,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> j) => PendingRequest(
        friendshipId: j['friendship_id'],
        id: j['id'],
        name: j['name'] ?? '',
        userCode: j['user_code'] ?? '',
        avatarPath: j['avatar_url'],
        avatarUrl: j['avatar_url'],
        level: j['level'] is Map ? LevelInfo.fromJson(j['level']) : null,
      );
}
