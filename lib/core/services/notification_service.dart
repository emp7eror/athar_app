import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Local notifications + the interactive "nudge" action category
/// (Yes I prayed / I'll pray soon / I won't pray). FCM messages arriving with
/// the ATHAR_NUDGE channel/category render these buttons.
class NotificationService extends GetxService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const nudgeChannelId = 'ATHAR_NUDGE';

  Future<NotificationService> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      // Don't request at init — the permission gate asks contextually so we
      // avoid a blind prompt the moment the app launches.
      // feras pernmsison to false
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          nudgeChannelId,
          actions: [
            DarwinNotificationAction.plain('yes_prayed', 'Yes, I prayed'),
            DarwinNotificationAction.plain('will_pray_soon', 'I will pray soon'),
            DarwinNotificationAction.plain('will_not_pray', "I won't pray"),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings:
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onAction,
    );

    // High-importance Android channel for the interactive nudge.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          nudgeChannelId,
          'Prayer Nudges',
          importance: Importance.high,
        ));

    // NOTE: We deliberately do NOT request the Android 13+ runtime
    // notification permission here. Requesting at launch is blind and causes
    // the "prompt every start" problem. The permission gate
    // (PermissionController) requests it contextually with an explanation.

    return this;
  }

  void _onAction(NotificationResponse r) {
    // Route the tapped action (r.actionId) — e.g. auto-mark a prayer, or ignore.
    debugPrint('Notification action: ${r.actionId}');
  }

  Future<void> showNudge(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        nudgeChannelId,
        'Prayer Nudges',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction('yes_prayed', 'Yes, I prayed'),
          AndroidNotificationAction('will_pray_soon', 'I will pray soon'),
          AndroidNotificationAction('will_not_pray', "I won't pray"),
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
}
