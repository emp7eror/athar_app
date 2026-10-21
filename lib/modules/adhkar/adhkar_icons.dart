import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'adhkar_models.dart';

/// The icons a reader can give one of their collections, by the key stored on
/// the server. Keep in step with AdhkarCollectionController::ICONS.
const adhkarIcons = <String, IconData>{
  'auto_stories': Icons.auto_stories_rounded,
  'menu_book': Icons.menu_book_rounded,
  'wb_sunny': Icons.wb_sunny_rounded,
  'nights_stay': Icons.nights_stay_rounded,
  'bedtime': Icons.bedtime_rounded,
  'mosque': Icons.mosque_rounded,
  'volunteer_activism': Icons.volunteer_activism_rounded,
  'favorite': Icons.favorite_rounded,
  'star': Icons.star_rounded,
  'auto_awesome': Icons.auto_awesome_rounded,
  'spa': Icons.spa_rounded,
  'local_florist': Icons.local_florist_rounded,
  'water_drop': Icons.water_drop_rounded,
  'healing': Icons.healing_rounded,
  'family_restroom': Icons.family_restroom_rounded,
  'home': Icons.home_rounded,
  'flight': Icons.flight_rounded,
  'restaurant': Icons.restaurant_rounded,
  'school': Icons.school_rounded,
  'work': Icons.work_rounded,
};

/// Icons for the public categories, by slug, so each one says what it holds.
/// Slugs are unique within a section; the two sections share a few (prayer,
/// travel, hajj-umrah, occasions), which take the same icon in both.
const _categoryIcons = <String, IconData>{
  // Adhkar.
  'morning': Icons.wb_sunny_rounded,
  'evening': Icons.nights_stay_rounded,
  'sleep-waking': Icons.bedtime_rounded,
  'prayer': Icons.mosque_rounded,
  'wudu-clothes-home': Icons.water_drop_rounded,
  'tasbih-istighfar': Icons.all_inclusive_rounded,
  'salawat': Icons.favorite_rounded,
  'ruqyah': Icons.shield_rounded,
  'hajj-umrah': Icons.place_rounded,
  'travel': Icons.flight_rounded,
  'social': Icons.groups_rounded,
  'sickness': Icons.healing_rounded,
  'occasions': Icons.event_rounded,
  // Duas.
  'paradise-and-hellfire': Icons.park_rounded,
  'forgiveness-and-mercy': Icons.volunteer_activism_rounded,
  'guidance-and-steadfastness': Icons.explore_rounded,
  'good-of-both-worlds': Icons.public_rounded,
  'parents-family-offspring': Icons.family_restroom_rounded,
  'religion-and-hereafter': Icons.auto_stories_rounded,
  'worldly-affairs': Icons.work_rounded,
  'pardon-and-wellbeing': Icons.spa_rounded,
  'refuge-from-ailments': Icons.health_and_safety_rounded,
  'refuge-from-trials': Icons.shield_rounded,
  'protection-and-victory': Icons.verified_user_rounded,
  'mosque-toilet-clothes': Icons.door_front_door_rounded,
  'night-sleep': Icons.bedtime_rounded,
  'hardship': Icons.cloud_rounded,
  'whispers': Icons.shield_moon_rounded,
  'the-sick': Icons.healing_rounded,
  'funerals': Icons.local_florist_rounded,
  'weather-moon': Icons.umbrella_rounded,
  'food-fasting': Icons.restaurant_rounded,
  'marriage': Icons.diamond_rounded,
  'people': Icons.groups_rounded,
};

/// A collection's icon: the reader's choice, else its category's, else
/// its kind's.
IconData adhkarIconFor(AdhkarCollection c) {
  final chosen = adhkarIcons[c.icon];
  if (chosen != null) return chosen;
  final byCategory = _categoryIcons[c.slug];
  if (byCategory != null) return byCategory;
  return c.type == AdhkarType.dua
      ? Icons.volunteer_activism_rounded
      : Icons.auto_stories_rounded;
}

/// The wording for [type]: `{key}_dua` or `{key}_dhikr` — «دعاء» or «ذكر»
/// rather than a neutral "item".
String adhkarWord(String key, AdhkarType type, [Map<String, String>? params]) {
  final full = '${key}_${type == AdhkarType.dua ? 'dua' : 'dhikr'}';
  return params == null ? full.tr : full.trParams(params);
}

/// «دعاء واحد / دعاءان / ٣ أدعية / ١١ دعاءً» — how many a collection holds.
String adhkarCountLabel(AdhkarType type, int n) {
  final form = switch (n) {
    0 => 'zero',
    1 => 'one',
    2 => 'two',
    <= 10 => 'few',
    _ => 'many',
  };
  return adhkarWord('adhkar_count_$form', type, {'n': '$n'});
}
