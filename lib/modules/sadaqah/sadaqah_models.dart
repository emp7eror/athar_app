import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A category of good deeds, as `GET /sadaqah` sends it. Only categories with
/// deeds are sent.
class SadaqahCategory {
  const SadaqahCategory({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.color,
    required this.icon,
    required this.deedsCount,
  });

  final String key;
  final String nameAr;
  final String nameEn;

  /// The chip's accent, from the server's catalog.
  final Color color;
  final String icon;
  final int deedsCount;

  /// The name in the app's language.
  String get name => Get.locale?.languageCode == 'en' ? nameEn : nameAr;

  factory SadaqahCategory.fromJson(Map<String, dynamic> j) => SadaqahCategory(
    key: j['key'] as String,
    nameAr: j['name_ar'] as String,
    nameEn: (j['name_en'] as String?) ?? j['name_ar'] as String,
    color: _parseColor(j['color'] as String?),
    icon: (j['icon'] as String?) ?? '',
    deedsCount: (j['deeds_count'] as num?)?.toInt() ?? 0,
  );

  static Color _parseColor(String? hex) {
    final value = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
    return value == null ? const Color(0xFF2E9E6B) : Color(0xFF000000 | value);
  }
}

/// Where a deed's merit is taught: a Quran passage or a hadith.
class SadaqahSource {
  const SadaqahSource({
    required this.type,
    required this.reference,
    required this.quoteType,
    required this.evidence,
    required this.verified,
    this.text,
    this.summary,
    this.grade,
    this.surah,
    this.ayat = const [],
  });

  /// القرآن الكريم or السنة النبوية.
  final String type;
  final String reference;

  /// The exact words, when there are any. A verse's text comes from the
  /// server's imported Uthmani text, so it can be missing until that exists.
  final String? text;

  /// The meaning in other words, for a source that isn't quoted exactly.
  final String? summary;

  /// نص (exact) or معنى (paraphrase).
  final String quoteType;
  final String? grade;

  /// نص صريح when the text names this deed; مبدأ عام when it supports it
  /// as part of a broader teaching.
  final String evidence;
  final bool verified;
  final int? surah;
  final List<int> ayat;

  bool get isQuran => surah != null;
  bool get isExplicit => evidence == 'نص صريح';

  factory SadaqahSource.fromJson(Map<String, dynamic> j) => SadaqahSource(
    type: j['type'] as String,
    reference: j['reference'] as String,
    text: j['text'] as String?,
    summary: j['summary'] as String?,
    quoteType: (j['quote_type'] as String?) ?? 'نص',
    grade: j['grade'] as String?,
    evidence: (j['evidence'] as String?) ?? '',
    verified: j['verified'] == true,
    surah: (j['surah'] as num?)?.toInt(),
    ayat: [
      for (final a in (j['ayat'] as List? ?? const [])) (a as num).toInt(),
    ],
  );
}

/// One good deed. Its text is Arabic, as the catalog is.
class SadaqahDeed {
  const SadaqahDeed({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.icon,
    required this.points,
    required this.benefit,
    required this.source,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String icon;

  /// Illustrative points, decided by the server.
  final int points;
  final String benefit;
  final SadaqahSource source;

  factory SadaqahDeed.fromJson(Map<String, dynamic> j) => SadaqahDeed(
    id: (j['id'] as num).toInt(),
    title: j['title'] as String,
    description: j['description'] as String,
    category: j['category'] as String,
    subcategory: (j['subcategory'] as String?) ?? '',
    icon: (j['icon'] as String?) ?? '',
    points: (j['points'] as num?)?.toInt() ?? 0,
    benefit: (j['benefit'] as String?) ?? '',
    source: SadaqahSource.fromJson(
      Map<String, dynamic>.from(j['source'] as Map),
    ),
  );
}

/// The user's sadaqah totals, as the server counts them.
class SadaqahStats {
  const SadaqahStats({required this.total, required this.points});

  /// Every sadaqah recorded.
  final int total;

  /// The points they earned (one sadaqah a day earns its points).
  final int points;

  factory SadaqahStats.fromJson(Map<String, dynamic> j) => SadaqahStats(
    total: (j['total'] as num?)?.toInt() ?? 0,
    points: (j['points'] as num?)?.toInt() ?? 0,
  );
}

/// The catalog's icon keys as Material icons. A key the app doesn't know yet
/// falls back to the section's own icon.
abstract final class SadaqahIcons {
  static const fallback = Icons.volunteer_activism_rounded;

  static IconData of(String key) => _icons[key] ?? fallback;

  static const _icons = <String, IconData>{
    'payments': Icons.payments_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'restaurant': Icons.restaurant_rounded,
    'water_drop': Icons.water_drop_rounded,
    'water_well': Icons.water_rounded,
    'checkroom': Icons.checkroom_rounded,
    'home': Icons.home_rounded,
    'house': Icons.house_rounded,
    'handshake': Icons.handshake_rounded,
    'healing': Icons.healing_rounded,
    'family': Icons.family_restroom_rounded,
    'shopping_basket': Icons.shopping_basket_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'chat': Icons.chat_rounded,
    'sentiment_satisfied': Icons.sentiment_satisfied_rounded,
    'tips': Icons.tips_and_updates_rounded,
    'campaign': Icons.campaign_rounded,
    'waving_hand': Icons.waving_hand_rounded,
    'thumb_up': Icons.thumb_up_rounded,
    'record_voice_over': Icons.record_voice_over_rounded,
    'luggage': Icons.luggage_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
    'directions': Icons.directions_rounded,
    'visibility': Icons.visibility_rounded,
    'support': Icons.support_rounded,
    'assignment': Icons.assignment_rounded,
    'emergency': Icons.emergency_rounded,
    'bloodtype': Icons.bloodtype_rounded,
    'construction': Icons.construction_rounded,
    'favorite': Icons.favorite_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'block': Icons.block_rounded,
    'celebration': Icons.celebration_rounded,
    'spa': Icons.spa_rounded,
    'redeem': Icons.redeem_rounded,
    'storefront': Icons.storefront_rounded,
    'coffee': Icons.coffee_rounded,
    'shield': Icons.shield_rounded,
    'elderly': Icons.elderly_rounded,
    'child_care': Icons.child_care_rounded,
    'accessible': Icons.accessible_rounded,
    'call': Icons.call_rounded,
    'groups': Icons.groups_rounded,
    'diversity_3': Icons.diversity_3_rounded,
    'mosque': Icons.mosque_rounded,
    'notifications': Icons.notifications_rounded,
    'park': Icons.park_rounded,
    'menu_book': Icons.menu_book_rounded,
    'school': Icons.school_rounded,
    'account_balance': Icons.account_balance_rounded,
    'lightbulb': Icons.lightbulb_rounded,
    'share': Icons.share_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    'pets': Icons.pets_rounded,
    'recycling': Icons.recycling_rounded,
    'eco': Icons.eco_rounded,
  };
}
