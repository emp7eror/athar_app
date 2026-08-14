/// Mirror of the backend LevelService tiers, for offline display when the
/// server payload isn't available yet.
class LevelTier {
  final int level;
  final int min;
  final int? max;
  final String titleAr;
  final String titleEn;
  const LevelTier(this.level, this.min, this.max, this.titleAr, this.titleEn);
}

class LevelThresholds {
  static const List<LevelTier> tiers = [
    LevelTier(1, 0, 500, 'المحافظ', 'The Preserver'),
    LevelTier(2, 501, 1500, 'المواظب', 'The Constant'),
    LevelTier(3, 1501, 3500, 'الذاكر', 'The Rememberer'),
    LevelTier(4, 3501, 7000, 'القانت', 'The Devout'),
    LevelTier(5, 7001, null, 'السابق بالخيرات', 'The Foremost in Good'),
  ];

  static LevelTier resolve(int points) {
    var current = tiers.first;
    for (final t in tiers) {
      if (points >= t.min) current = t;
    }
    return current;
  }
}
