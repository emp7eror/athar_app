import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Key-value persistence for JWT, coordinates, language, and cached user.
class StorageProvider extends GetxService {
  final _box = GetStorage();

  static const _kToken = 'token';
  static const _kLat = 'lat';
  static const _kLng = 'lng';
  static const _kCityAr = 'cityAr';
  static const _kCityEn = 'cityEn';
  static const _kUser = 'user';
  static const _kSeenOnboarding = 'seen_onboarding';
  static const _kLocationSetBefore = 'location_set_before';
  static const _kDarkMode = 'dark_mode';

  // ── Notification preferences ──
  static const _kNotifPrayer = 'notif_prayer_enabled';
  static const _kNotifPostPrayer = 'notif_post_prayer_enabled';
  static const _kNotifUpcoming = 'notif_upcoming_enabled';
  static const _kPrayerSound = 'notif_prayer_sound';
  static const _kReminderSound = 'notif_reminder_sound';

  // ── Leaderboard ──
  static const _kLeaderboardPeriod = 'leaderboard_period';
  static const _kLeaderboardScope = 'leaderboard_scope';
  static const _kLeaderboardTab = 'leaderboard_tab';

  String? get token => _box.read(_kToken);
  set token(String? v) => v == null ? _box.remove(_kToken) : _box.write(_kToken, v);

  bool get seenOnboarding => _box.read(_kSeenOnboarding) ?? false;
  set seenOnboarding(bool v) => _box.write(_kSeenOnboarding, v);

  bool get locationSetBefore => _box.read(_kLocationSetBefore) ?? false;
  set locationSetBefore(bool v) => _box.write(_kLocationSetBefore, v);

  bool get darkMode => _box.read(_kDarkMode) ?? false;
  set darkMode(bool v) => _box.write(_kDarkMode, v);

  // ── Notification preferences (default: all reminder types on) ──
  bool get notifPrayerEnabled => _box.read(_kNotifPrayer) ?? true;
  set notifPrayerEnabled(bool v) => _box.write(_kNotifPrayer, v);

  bool get notifPostPrayerEnabled => _box.read(_kNotifPostPrayer) ?? true;
  set notifPostPrayerEnabled(bool v) => _box.write(_kNotifPostPrayer, v);

  bool get notifUpcomingEnabled => _box.read(_kNotifUpcoming) ?? true;
  set notifUpcomingEnabled(bool v) => _box.write(_kNotifUpcoming, v);

  String get prayerSoundId => _box.read(_kPrayerSound) ?? 'athan1';
  set prayerSoundId(String v) => _box.write(_kPrayerSound, v);

  String get reminderSoundId => _box.read(_kReminderSound) ?? 'athan_reminder_1';
  set reminderSoundId(String v) => _box.write(_kReminderSound, v);

  /// One of 'current_month' | 'all'. Old rolling-window selections are
  /// migrated to the current-month score ranking.
  String get leaderboardPeriod {
    final value = _box.read(_kLeaderboardPeriod) as String?;
    return value == 'all' || value == 'current_month' ? value! : 'current_month';
  }
  set leaderboardPeriod(String v) => _box.write(_kLeaderboardPeriod, v);

  String get leaderboardScope => _box.read(_kLeaderboardScope) ?? 'global';
  set leaderboardScope(String v) => _box.write(_kLeaderboardScope, v);

  String get leaderboardTab => _box.read(_kLeaderboardTab) ?? 'points';
  set leaderboardTab(String v) => _box.write(_kLeaderboardTab, v);

  double? get lat => _box.read(_kLat);
  double? get lng => _box.read(_kLng);
  String? get cityAr => _box.read(_kCityAr);
  String? get cityEn => _box.read(_kCityEn);

  void saveCoords(double lat, double lng) {
    _box.write(_kLat, lat);
    _box.write(_kLng, lng);
  }

  void saveCity(String? nameAr, String? nameEn) {
    if (nameAr != null) _box.write(_kCityAr, nameAr);
    if (nameEn != null) _box.write(_kCityEn, nameEn);
  }

  Map<String, dynamic>? get cachedUser => _box.read(_kUser);
  set cachedUser(Map<String, dynamic>? v) =>
      v == null ? _box.remove(_kUser) : _box.write(_kUser, v);

  bool get isLoggedIn => (token ?? '').isNotEmpty;

  void clear() {
    _box.remove(_kToken);
    _box.remove(_kUser);
  }
}
