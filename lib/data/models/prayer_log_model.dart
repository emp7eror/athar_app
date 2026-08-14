class PrayerChecklistItem {
  final String prayerName;
  final int points, pointsEarned;
  final bool isCompleted;
  final String? completedAt;

  PrayerChecklistItem({
    required this.prayerName,
    required this.points,
    required this.pointsEarned,
    required this.isCompleted,
    this.completedAt,
  });

  factory PrayerChecklistItem.fromJson(Map<String, dynamic> j) => PrayerChecklistItem(
        prayerName: j['prayer_name'],
        points: j['points'] ?? 0,
        pointsEarned: j['points_earned'] ?? 0,
        isCompleted: j['is_completed'] ?? false,
        completedAt: j['completed_at'],
      );
}
