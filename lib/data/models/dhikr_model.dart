/// One dhikr's state for the current day, as reported by the server.
///
/// [count] and [rewardGranted] are always the server's values — the UI may show
/// an optimistic count on top while taps are still queued, but never persists
/// its own idea of whether the reward was earned.
class DhikrState {
  const DhikrState({
    required this.key,
    required this.count,
    required this.rewardGranted,
  });

  final String key;
  final int count;
  final bool rewardGranted;

  factory DhikrState.fromJson(Map<String, dynamic> json) => DhikrState(
        key: json['key']?.toString() ?? '',
        count: _asInt(json['count']),
        rewardGranted: json['reward_granted'] == true,
      );

  DhikrState copyWith({int? count, bool? rewardGranted}) => DhikrState(
        key: key,
        count: count ?? this.count,
        rewardGranted: rewardGranted ?? this.rewardGranted,
      );

  static int _asInt(dynamic v) => (v as num?)?.round() ?? 0;
}

/// The whole day's dhikr payload: the shared target plus one entry per dhikr.
class DhikrDay {
  const DhikrDay({
    required this.date,
    required this.target,
    required this.rewardPoints,
    required this.items,
  });

  final String date;
  final int target;
  final int rewardPoints;
  final List<DhikrState> items;

  factory DhikrDay.fromJson(Map<String, dynamic> json) => DhikrDay(
        date: json['date']?.toString() ?? '',
        target: DhikrState._asInt(json['target']),
        rewardPoints: DhikrState._asInt(json['reward_points']),
        items: (json['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => DhikrState.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
