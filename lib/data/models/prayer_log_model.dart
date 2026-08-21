class PrayerChecklistItem {
  final String prayerName;
  final int points, pointsEarned;
  final bool isCompleted;
  final bool performedOutsideTime;
  final bool onTimeBonusAwarded;
  final String? completedAt;
  final DateTime? time;

  PrayerChecklistItem({
    required this.prayerName,
    required this.points,
    required this.pointsEarned,
    required this.isCompleted,
    this.performedOutsideTime = false,
    this.onTimeBonusAwarded = false,
    this.completedAt,
    this.time,
  });

  /// True only for prayers that are done AND were completed on time.
  bool get isOnTimeCompleted => isCompleted && !performedOutsideTime;

  /// True only for prayers that are done but recorded after their window.
  bool get isLateCompleted => isCompleted && performedOutsideTime;

  /// True only for prayers that are done but recorded after their window.
  bool get isOnTimeEarlyCompleted => isCompleted && !performedOutsideTime && onTimeBonusAwarded;

  factory PrayerChecklistItem.fromJson(Map<String, dynamic> j) => PrayerChecklistItem(
    prayerName: j['prayer_name'],
    points: j['points'] ?? 0,
    pointsEarned: j['points_earned'] ?? 0,
    isCompleted: j['is_completed'] ?? false,
    // Tolerant to backend not yet sending the field.
    performedOutsideTime: j['performed_outside_time'] ?? false,
    onTimeBonusAwarded: j['on_time_bonus_awarded'] ?? false,
    completedAt: j['completed_at'],
  );

  PrayerChecklistItem copyWith({DateTime? time, bool? isCompleted, bool? performedOutsideTime}) => PrayerChecklistItem(
    prayerName: prayerName,
    points: points,
    pointsEarned: pointsEarned,
    isCompleted: isCompleted ?? this.isCompleted,
    performedOutsideTime: performedOutsideTime ?? this.performedOutsideTime,
    onTimeBonusAwarded: onTimeBonusAwarded ?? this.onTimeBonusAwarded,
    completedAt: completedAt,
    time: time ?? this.time,
  );
}
