/// Coerces a JSON-decoded number to `int` whether it arrived as an `int` or
/// a `double` (PHP's `round()` returns a float, and depending on server
/// config `json_encode` can emit a whole number like `6.0`, which Dart's
/// decoder reads back as a `double` — a raw `as int` cast on that throws).
int _asInt(dynamic v, [int fallback = 0]) => (v as num?)?.round() ?? fallback;

/// Per-prayer breakdown within [PrayerInsights.perPrayer].
class PrayerStat {
  final String prayerName;
  final int completionRate, onTimeRate, missedCount;

  PrayerStat({
    required this.prayerName,
    required this.completionRate,
    required this.onTimeRate,
    required this.missedCount,
  });

  factory PrayerStat.fromJson(Map<String, dynamic> j) => PrayerStat(
        prayerName: j['prayer_name'] ?? '',
        completionRate: _asInt(j['completion_rate']),
        onTimeRate: _asInt(j['on_time_rate']),
        missedCount: _asInt(j['missed_count']),
      );
}

/// One weekday's completion rate within [PrayerInsights.weekdayPattern].
/// [weekday] is 0=Sunday..6=Saturday (matches `DateTime.sunday`..`saturday`
/// once converted — see `CoachInsightEngine`).
class WeekdayStat {
  final int weekday;
  final int completionRate, samples;

  WeekdayStat({required this.weekday, required this.completionRate, required this.samples});

  factory WeekdayStat.fromJson(Map<String, dynamic> j) => WeekdayStat(
        weekday: _asInt(j['weekday']),
        completionRate: _asInt(j['completion_rate']),
        samples: _asInt(j['samples']),
      );
}

/// One coaching card generated and worded server-side.
class InsightCard {
  /// One of: positive | warning | info.
  final String tone;
  final String title, message;

  InsightCard({required this.tone, required this.title, required this.message});

  factory InsightCard.fromJson(Map<String, dynamic> j) => InsightCard(
        tone: j['tone'] ?? 'info',
        title: j['title'] ?? '',
        message: j['message'] ?? '',
      );
}

/// An honorific the coach awarded the user based on this report — e.g.
/// "المحافظ على الفجر" — with a one-line justification.
class UserTitle {
  final String label, reason;

  UserTitle({required this.label, required this.reason});

  factory UserTitle.fromJson(Map<String, dynamic> j) => UserTitle(
        label: j['label'] ?? '',
        reason: j['reason'] ?? '',
      );
}

/// Ready-to-render coaching section built on the server (see AiInsightService).
/// Absent when the server has nothing generated — the client then falls back
/// to its own rule-based cards.
class InsightSection {
  final String title;
  final DateTime? generatedAt;
  final UserTitle? userTitle;
  final List<InsightCard> cards;

  InsightSection({
    required this.title,
    this.generatedAt,
    this.userTitle,
    this.cards = const [],
  });

  factory InsightSection.fromJson(Map<String, dynamic> j) => InsightSection(
        title: j['title'] ?? '',
        generatedAt: DateTime.tryParse('${j['generated_at']}'),
        userTitle: j['user_title'] is Map
            ? UserTitle.fromJson(Map<String, dynamic>.from(j['user_title']))
            : null,
        cards: (j['cards'] as List? ?? [])
            .map((e) => InsightCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Structured 30-day prayer analysis from `GET /stats/insights`, plus the
/// server-generated [section] when one is available.
class PrayerInsights {
  final bool insufficientData;
  final int periodDays;
  final int overallCompletionRate, overallOnTimeRate;
  final int trendFirstHalfRate, trendSecondHalfRate;
  final String trendDirection; // improving | declining | steady
  final List<PrayerStat> perPrayer;
  final String? bestPrayer, weakestPrayer, topMissedReason;
  final List<WeekdayStat> weekdayPattern;
  final int? notableWeekday;
  final Map<String, int> reasonCounts;
  final InsightSection? section;

  PrayerInsights({
    required this.insufficientData,
    required this.periodDays,
    this.overallCompletionRate = 0,
    this.overallOnTimeRate = 0,
    this.trendFirstHalfRate = 0,
    this.trendSecondHalfRate = 0,
    this.trendDirection = 'steady',
    this.perPrayer = const [],
    this.bestPrayer,
    this.weakestPrayer,
    this.topMissedReason,
    this.weekdayPattern = const [],
    this.notableWeekday,
    this.reasonCounts = const {},
    this.section,
  });

  factory PrayerInsights.fromJson(Map<String, dynamic> j) => PrayerInsights(
        insufficientData: j['insufficient_data'] == true,
        periodDays: _asInt(j['period_days']),
        overallCompletionRate: _asInt(j['overall']?['completion_rate']),
        overallOnTimeRate: _asInt(j['overall']?['on_time_rate']),
        trendFirstHalfRate: _asInt(j['trend']?['first_half_rate']),
        trendSecondHalfRate: _asInt(j['trend']?['second_half_rate']),
        trendDirection: j['trend']?['direction'] ?? 'steady',
        perPrayer: (j['per_prayer'] as List? ?? [])
            .map((e) => PrayerStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        bestPrayer: j['best_prayer'],
        weakestPrayer: j['weakest_prayer'],
        topMissedReason: j['top_missed_reason'],
        weekdayPattern: (j['weekday_pattern'] as List? ?? [])
            .map((e) => WeekdayStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        notableWeekday: j['notable_weekday'] == null ? null : _asInt(j['notable_weekday']),
        // reasonCounts: Map<String, int>.fromEntries(
        //   (j['reason_counts'] as Map<String, dynamic>? ?? {})
        //       .entries
        //       .map((e) => MapEntry(e.key, _asInt(e.value))),
        // ),
        section: j['section'] is Map
            ? InsightSection.fromJson(Map<String, dynamic>.from(j['section']))
            : null,
      );
}
