import 'package:flutter/material.dart';

/// An activity category, by the id the server uses. Labels and icons are the
/// app's; filtering always sends [id].
class WorldCategory {
  const WorldCategory(this.id, this.labelKey, this.icon);

  final String id;
  final String labelKey;
  final IconData icon;

  static const all = [
    WorldCategory('prayer', 'my_world_cat_prayer', Icons.mosque_rounded),
    WorldCategory('tasbih', 'my_world_cat_tasbih', Icons.blur_circular_rounded),
    WorldCategory('istighfar', 'my_world_cat_istighfar', Icons.spa_rounded),
    WorldCategory('sadaqah', 'my_world_cat_sadaqah', Icons.volunteer_activism_rounded),
    WorldCategory('quran', 'my_world_cat_quran', Icons.menu_book_rounded),
  ];

  static List<String> get ids => [for (final c in all) c.id];

  static WorldCategory? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}

Map<String, int> _counts(dynamic json) => {
  if (json is Map)
    for (final e in json.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
};

/// One hotspot: a grid cell's records, as the server aggregated them. The
/// position is the cell's centroid rounded to the zoom level's precision.
class WorldCluster {
  const WorldCluster({
    required this.id,
    required this.lat,
    required this.lng,
    required this.total,
    required this.counts,
    required this.intensity,
    required this.approximate,
  });

  factory WorldCluster.fromJson(Map<String, dynamic> json) => WorldCluster(
    id: json['id'].toString(),
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    total: (json['total'] as num?)?.toInt() ?? 0,
    counts: _counts(json['counts']),
    intensity: ((json['intensity'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
    approximate: json['approximate'] == true,
  );

  final String id;
  final double lat;
  final double lng;
  final int total;
  final Map<String, int> counts;

  /// 0..1 on the server's log scale; drives brightness and halo size.
  final double intensity;

  /// Placed by country only (no stored coordinates).
  final bool approximate;
}

/// The totals behind the filters and the empty states.
class WorldMeta {
  const WorldMeta({
    required this.categoryTotals,
    required this.totalRecords,
    required this.filteredRecords,
    required this.visibleTotal,
    required this.unmapped,
    required this.maxCluster,
  });

  factory WorldMeta.fromJson(Map<String, dynamic> json) => WorldMeta(
    categoryTotals: _counts(json['category_totals']),
    totalRecords: (json['total_records'] as num?)?.toInt() ?? 0,
    filteredRecords: (json['filtered_records'] as num?)?.toInt() ?? 0,
    visibleTotal: (json['visible_total'] as num?)?.toInt() ?? 0,
    unmapped: (json['unmapped'] as num?)?.toInt() ?? 0,
    maxCluster: (json['max_cluster'] as num?)?.toInt() ?? 0,
  );

  /// Every category's records, unfiltered.
  final Map<String, int> categoryTotals;
  final int totalRecords;

  /// Records in the selected categories, placed or not.
  final int filteredRecords;

  /// Records on the globe for the selected categories.
  final int visibleTotal;

  /// Records in the selected categories with no usable location.
  final int unmapped;
  final int maxCluster;
}

/// A tapped cluster, described.
class WorldClusterDetails {
  const WorldClusterDetails({
    required this.id,
    required this.total,
    required this.counts,
    required this.approximate,
    this.city,
    this.country,
  });

  factory WorldClusterDetails.fromJson(Map<String, dynamic> json) {
    final area = json['area'] is Map ? Map<String, dynamic>.from(json['area'] as Map) : const <String, dynamic>{};
    return WorldClusterDetails(
      id: json['id'].toString(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      counts: _counts(json['counts']),
      approximate: json['approximate'] == true,
      city: area['city']?.toString(),
      country: area['country']?.toString(),
    );
  }

  final String id;
  final int total;
  final Map<String, int> counts;
  final bool approximate;
  final String? city;
  final String? country;
}

/// One record in a cluster's list.
class WorldRecord {
  const WorldRecord({
    required this.key,
    required this.category,
    required this.day,
    this.occurredAt,
    this.detail,
    this.amount,
  });

  factory WorldRecord.fromJson(Map<String, dynamic> json) => WorldRecord(
    key: json['key'].toString(),
    category: json['category'].toString(),
    day: DateTime.tryParse(json['day']?.toString() ?? '') ?? DateTime(1970),
    occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? '')?.toLocal(),
    detail: json['detail']?.toString(),
    amount: (json['amount'] as num?)?.toInt(),
  );

  final String key;
  final String category;
  final DateTime day;
  final DateTime? occurredAt;

  /// The prayer's name, the sadaqah deed's title or the Quran page.
  final String? detail;

  /// Repetitions for a dhikr, points for a sadaqah, readings of a page.
  final int? amount;
}
