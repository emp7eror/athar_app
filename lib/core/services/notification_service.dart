import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/providers/storage_provider.dart';
import '../constants/notification_sounds.dart';

/// Whether the OS will actually deliver a notification we post right now.
enum NotifStatus {
  ready, // permission granted AND notifications enabled at the OS level
  denied, // can still be requested
  blocked, // permanently denied / disabled — only Settings can fix it
}

/// Centralised local-notification plumbing for Athar.
///
/// Owns: timezone init, Android channels (one per selectable sound so the OS
/// honours the user's choice — channel sound is immutable once created),
/// permission checks, the low-level schedule/cancel primitives used by
/// [PrayerNotificationScheduler], the in-app "test" notification, and the
/// foreground bridge for FCM friend-reminder messages.
class NotificationService extends GetxService {
  final _plugin = FlutterLocalNotificationsPlugin();

  // ── Channel ids ──
  static const nudgeChannelId = 'ATHAR_NUDGE';
  static const _prayerChannelPrefix = 'athar_prayer_';
  static const _reminderChannelPrefix = 'athar_reminder_';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<NotificationService> init() async {
    await _initTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      // The permission gate asks contextually — don't prompt blindly at launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          nudgeChannelId,
          actions: [
            DarwinNotificationAction.plain('yes_prayed',     'yes_prayed'.tr),
            DarwinNotificationAction.plain('will_pray_soon',  'will_pray_soon'.tr),
            DarwinNotificationAction.plain('will_not_pray',   'will_not_pray'.tr),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onAction,
    );

    await _createAndroidChannels();
    _bindForegroundMessages();
    return this;
  }

  Future<void> _initTimezone() async {
    tzdata.initializeTimeZones();
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC rather than crashing scheduling.
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  /// Pre-create one high-importance channel per selectable sound. Because a
  /// channel's sound is fixed at creation time on Android 8+, selecting a
  /// different sound simply means posting on a different channel.
  Future<void> _createAndroidChannels() async {
    final a = _android;
    if (a == null) return;

    for (final s in NotificationSounds.prayer) {
      await a.createNotificationChannel(AndroidNotificationChannel(
        '$_prayerChannelPrefix${s.id}',
        'Prayer Time',
        description: 'Adhan notification at prayer time',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound(s.androidRaw),
        playSound: true,
      ));
    }
    for (final s in NotificationSounds.reminder) {
      await a.createNotificationChannel(AndroidNotificationChannel(
        '$_reminderChannelPrefix${s.id}',
        'Prayer Reminders',
        description: 'Before / after prayer reminders',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(s.androidRaw),
        playSound: true,
      ));
    }
    await a.createNotificationChannel(const AndroidNotificationChannel(
      nudgeChannelId,
      'Prayer Nudges',
      description: 'Reminders sent by your friends',
      importance: Importance.high,
    ));
  }

  // ── Permission verification ─────────────────────────────────────────
  // The scheduler and settings screen ask this before scheduling so we never
  // "silently fail".

  Future<NotifStatus> checkStatus() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final enabled = await _android?.areNotificationsEnabled() ?? true;
      return enabled ? NotifStatus.ready : NotifStatus.blocked;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.checkPermissions();
    if (granted == null) return NotifStatus.ready;
    return granted.isEnabled ? NotifStatus.ready : NotifStatus.blocked;
  }

  Future<bool> get isReady async => (await checkStatus()) == NotifStatus.ready;

  /// Requests the runtime notification permission (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
  }

  /// On Android 12+ exact alarms may need a one-off grant; prayer reminders
  /// qualify as alarm-clock usage so we request it up front.
  Future<void> ensureExactAlarms() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final canExact = await _android?.canScheduleExactNotifications() ?? true;
    if (!canExact) {
      await _android?.requestExactAlarmsPermission();
    }
  }

  // ── Scheduling primitives (used by PrayerNotificationScheduler) ─────

  /// Schedule a single zoned notification. [prayerSound] selects the prayer
  /// channel/sound vs. the reminder channel/sound.
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required bool prayerSound,
    String? payload,
  }) async {
    if (!when.isAfter(DateTime.now())) return; // never schedule in the past

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _detailsFor(prayerSound: prayerSound),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  NotificationDetails _detailsFor({required bool prayerSound}) {
    final store = Get.find<StorageProvider>();
    if (prayerSound) {
      final s = NotificationSounds.prayerById(store.prayerSoundId);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          '$_prayerChannelPrefix${s.id}',
          'Prayer Time',
          channelDescription: 'Adhan notification at prayer time',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound(s.androidRaw),
        ),
        iOS: DarwinNotificationDetails(sound: s.iosFile),
      );
    }
    final s = NotificationSounds.reminderById(store.reminderSoundId);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        '$_reminderChannelPrefix${s.id}',
        'Prayer Reminders',
        channelDescription: 'Before / after prayer reminders',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(s.androidRaw),
      ),
      iOS: DarwinNotificationDetails(sound: s.iosFile),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  // ── Immediate notifications ─────────────────────────────────────────

  /// Fired by the "Test Notification" button in settings.
  Future<void> showTest(String title, String body) async {
    await _plugin.show(
      id: 100000,
      title: title,
      body: body,
      notificationDetails: _detailsFor(prayerSound: true),
    );
  }

  /// Interactive friend "nudge" (also used for FCM foreground rendering).
  Future<void> showNudge(String title, String body) async {
    if (!await isReady) return; // respect the OS notification switch
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        nudgeChannelId,
        'Prayer Nudges',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction('yes_prayed',     'yes_prayed'.tr),
          AndroidNotificationAction('will_pray_soon',  'will_pray_soon'.tr),
          AndroidNotificationAction('will_not_pray',   'will_not_pray'.tr),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: nudgeChannelId),
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ── FCM foreground bridge ───────────────────────────────────────────
  // Background & terminated FCM notification messages are rendered by the OS;
  // in the foreground we render them ourselves so friend reminders are never
  // swallowed.
  void _bindForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      showNudge(n.title ?? 'nudge'.tr, n.body ?? '');
    });
  }

  void _onAction(NotificationResponse r) {
    debugPrint('Notification action: ${r.actionId} payload=${r.payload}');
  }
}
