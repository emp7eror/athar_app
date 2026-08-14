class FriendModel {
  final int id;
  final String name, userCode;
  final String? avatarPath;
  final int totalPoints, currentStreak, todayPoints;
  final double todayProgress;

  FriendModel({
    required this.id,
    required this.name,
    required this.userCode,
    this.avatarPath,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.todayPoints = 0,
    this.todayProgress = 0,
  });

  factory FriendModel.fromJson(Map<String, dynamic> j) => FriendModel(
        id: j['id'],
        name: j['name'] ?? '',
        userCode: j['user_code'] ?? '',
        avatarPath: j['avatar_path'],
        totalPoints: j['total_points'] ?? 0,
        currentStreak: j['current_streak'] ?? 0,
        todayPoints: j['today_points'] ?? 0,
        todayProgress: (j['today_progress'] ?? 0).toDouble(),
      );
}

class PendingRequest {
  final int friendshipId, id;
  final String name, userCode;
  PendingRequest({required this.friendshipId, required this.id, required this.name, required this.userCode});

  factory PendingRequest.fromJson(Map<String, dynamic> j) => PendingRequest(
        friendshipId: j['friendship_id'],
        id: j['id'],
        name: j['name'] ?? '',
        userCode: j['user_code'] ?? '',
      );
}
