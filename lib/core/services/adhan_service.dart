import 'package:adhan/adhan.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// On-device prayer-time math (offline-first). No backend call required.
class AdhanService extends GetxService {
  final _box = GetStorage();

  Coordinates get _coordinates {
    final lat = (_box.read('lat') as num?)?.toDouble() ?? 21.4225; // Makkah default
    final lng = (_box.read('lng') as num?)?.toDouble() ?? 39.8262;
    return Coordinates(lat, lng);
  }

  CalculationParameters get _params {
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    return params;
  }

  PrayerTimes getTodayPrayerTimes({DateTime? date}) {
    final lat = (_box.read('lat') as num?)?.toDouble() ?? 21.4225;
    final lng = (_box.read('lng') as num?)?.toDouble() ?? 39.8262;
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    if (date != null) {
      final c = DateComponents(date.year, date.month, date.day);
      return PrayerTimes(coordinates, c, params);
    }
    return PrayerTimes.today(coordinates, params);
  }

  /// Prayer times for an arbitrary calendar date (same coordinates / method).
  /// Used by the scheduler to lay out several days of notifications ahead.
  PrayerTimes prayerTimesForDate(DateTime date) => PrayerTimes(_coordinates, DateComponents.from(date), _params);

  /// The five daily prayers as ordered (key, time) pairs for a given date.
  List<({String key, DateTime time})> orderedTimes(DateTime date) {
    final t = prayerTimesForDate(date);
    return [
      (key: 'fajr', time: t.fajr),
      (key: 'dhuhr', time: t.dhuhr),
      (key: 'asr', time: t.asr),
      (key: 'maghrib', time: t.maghrib),
      (key: 'isha', time: t.isha),
    ];
  }

  /// Enforces the Prayer Time Availability Window locally:
  /// start <= now < next_start, with Fajr bounded by sunrise (Shuruq).
  bool isPrayerTimeActive(Prayer prayer) {
    final now         = DateTime.now();
    final todayTimes  = getTodayPrayerTimes();
    final isBeforeFajr = now.isBefore(todayTimes.fajr);

    // قبل الفجر نتعامل مع يوم أمس (نفس قاعدة العرض والتسجيل)
    final t = isBeforeFajr
        ? getTodayPrayerTimes(date: now.subtract(const Duration(days: 1)))
        : todayTimes;

    switch (prayer) {
      case Prayer.fajr:
      // الفجر يبقى مرتبطاً باليوم الحالي دائماً
        return now.isAfter(todayTimes.fajr) && now.isBefore(todayTimes.dhuhr);
      case Prayer.dhuhr:
        return now.isAfter(t.dhuhr) && now.isBefore(t.asr);
      case Prayer.asr:
        return now.isAfter(t.asr) && now.isBefore(t.maghrib);
      case Prayer.maghrib:
        return now.isAfter(t.maghrib) && now.isBefore(t.isha);
      case Prayer.isha:
      // نشط من العشاء حتى فجر اليوم التالي
        final nextFajr = isBeforeFajr
            ? todayTimes.fajr   // اليوم الحالي هو "غد" أمس
            : getTodayPrayerTimes(date: now.add(const Duration(days: 1))).fajr;
        return now.isAfter(t.isha) && now.isBefore(nextFajr);
      default:
        return false;
    }
  }

  DateTime timeFor(Prayer p) {
    final t = getTodayPrayerTimes();
    switch (p) {
      case Prayer.fajr:
        return t.fajr;
      case Prayer.dhuhr:
        return t.dhuhr;
      case Prayer.asr:
        return t.asr;
      case Prayer.maghrib:
        return t.maghrib;
      case Prayer.isha:
        return t.isha;
      default:
        return t.fajr;
    }
  }

  /// Returns the next upcoming prayer and its time (falls back to tomorrow's Fajr).
  ({Prayer prayer, DateTime time}) nextPrayer() {
    final t = getTodayPrayerTimes();
    final now = DateTime.now();
    final order = [(Prayer.fajr, t.fajr), (Prayer.dhuhr, t.dhuhr), (Prayer.asr, t.asr), (Prayer.maghrib, t.maghrib), (Prayer.isha, t.isha)];
    for (final (p, time) in order) {
      if (time.isAfter(now)) return (prayer: p, time: time);
    }
    // After Isha: next is tomorrow's Fajr (approx by +1 day on today's fajr).
    return (prayer: Prayer.fajr, time: t.fajr.add(const Duration(days: 1)));
  }

  static String prayerKey(Prayer p) => p.name; // fajr/dhuhr/asr/maghrib/isha
}
