import 'package:get/get.dart';

import '../../data/providers/storage_provider.dart';
import 'adhan_service.dart';
import 'notification_service.dart';

/// The single owner of *what* prayer notifications exist and *when*.
///
/// It lays out several days ahead so reminders keep firing even if the app is
/// never reopened, and it fully rebuilds the schedule on every call — cancelling
/// the previous set first — so prayer-time drift, settings changes and locale
/// changes can never leave stale or duplicated notifications behind.
class PrayerNotificationScheduler extends GetxService {
  final _notif = Get.find<NotificationService>();
  final _adhan = Get.find<AdhanService>();
  final _store = Get.find<StorageProvider>();

  /// How many days ahead to schedule. Covers long stretches without the app
  /// being opened; re-run on each app resume tops this back up.
  static const _daysAhead = 7;

  // Deterministic id layout keeps rescheduling collision-free and lets us
  // cancel the whole set without touching friend-nudge ids (which are epoch
  // seconds, far above this range).
  static const _idBase = 200000;
  static const _prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  static const _typePrayer = 0; // at prayer time
  static const _typePost = 1; // 30 min after
  static const _typeUpcoming = 2; // 20 min before

  static const _postDelay = Duration(minutes: 30);
  static const _upcomingLead = Duration(minutes: 20);

  bool _busy = false;

  int _id(int dayOffset, int prayerIndex, int type) =>
      _idBase + dayOffset * 100 + prayerIndex * 10 + type;

  Iterable<int> get _allIds sync* {
    for (var d = 0; d < _daysAhead; d++) {
      for (var p = 0; p < _prayerKeys.length; p++) {
        for (var t = _typePrayer; t <= _typeUpcoming; t++) {
          yield _id(d, p, t);
        }
      }
    }
  }

  /// Rebuild the entire prayer-notification schedule from current prayer times
  /// and settings. Safe to call repeatedly. Returns the OS delivery status so
  /// callers can surface a "notifications are off" explanation.
  Future<NotifStatus> reschedule() async {
    if (_busy) return _notif.checkStatus();
    _busy = true;
    try {
      await _notif.ensureExactAlarms();
      final status = await _notif.checkStatus();

      // Always clear the old set first — prevents duplicates and removes
      // notifications for reminder types the user just disabled.
      await _notif.cancelMany(_allIds);

      if (status != NotifStatus.ready) return status;

      final prayerOn = _store.notifPrayerEnabled;
      final postOn = _store.notifPostPrayerEnabled;
      final upcomingOn = _store.notifUpcomingEnabled;
      if (!prayerOn && !postOn && !upcomingOn) return status;

      final today = DateTime.now();
      for (var d = 0; d < _daysAhead; d++) {
        final date = DateTime(today.year, today.month, today.day + d);
        final times = _adhan.orderedTimes(date);
        for (var p = 0; p < times.length; p++) {
          final key = times[p].key;
          final time = times[p].time;
          final name = key.tr;

          if (prayerOn) {
            await _notif.scheduleAt(
              id: _id(d, p, _typePrayer),
              when: time,
              title: name,
              body: 'notif_prayer_time_body'.trParams({'prayer': name}),
              prayerSound: true,
              payload: 'prayer:$key',
            );
          }
          if (postOn) {
            await _notif.scheduleAt(
              id: _id(d, p, _typePost),
              when: time.add(_postDelay),
              title: name,
              body: 'notif_post_prayer_body'.trParams({'prayer': name}),
              prayerSound: false,
              payload: 'post:$key',
            );
          }
          if (upcomingOn) {
            await _notif.scheduleAt(
              id: _id(d, p, _typeUpcoming),
              when: time.subtract(_upcomingLead),
              title: 'notif_upcoming_title'.tr,
              body: 'notif_upcoming_body'.trParams({
                'prayer': name,
                'min': '${_upcomingLead.inMinutes}',
              }),
              prayerSound: false,
              payload: 'upcoming:$key',
            );
          }
        }
      }
      return status;
    } finally {
      _busy = false;
    }
  }

  /// Remove every prayer notification (e.g. on logout).
  Future<void> cancelAll() => _notif.cancelMany(_allIds);

  /// Cancels the still-pending reminders for one prayer once it's been
  /// marked complete — otherwise the pre-scheduled "did you pray?" nudges
  /// (at prayer time, and 30 min after) still fire even though the user
  /// already logged it. [occurredOn] is the prayer's own date (from its
  /// scheduled `DateTime`), not necessarily "today" — falls back to today
  /// if unknown.
  Future<void> cancelRemindersFor(String prayerKey, {DateTime? occurredOn}) async {
    final prayerIndex = _prayerKeys.indexOf(prayerKey);
    if (prayerIndex == -1) return;

    final target = occurredOn ?? DateTime.now();
    final today = DateTime.now();
    final dayOffset = DateTime(target.year, target.month, target.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (dayOffset < 0 || dayOffset >= _daysAhead) return;

    await _notif.cancelMany([
      _id(dayOffset, prayerIndex, _typePrayer),
      _id(dayOffset, prayerIndex, _typePost),
    ]);
  }
}
