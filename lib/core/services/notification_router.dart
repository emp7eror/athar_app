import 'package:flutter/widgets.dart';

import '../../modules/profile_preview/profile_preview_modal.dart';

/// Routes a tapped notification to the right screen. Shared by the three
/// paths Firebase/local-notifications can deliver a tap on:
///   * foreground → re-posted locally, tapped → NotificationService._onAction
///   * background (app in memory) → FirebaseMessaging.onMessageOpenedApp
///   * terminated (cold start)     → FirebaseMessaging.instance.getInitialMessage()
class NotificationRouter {
  /// Friend activity whose notification opens that friend's profile: a level
  /// reached, the day's Quran reward taken, a khatma completed.
  static const profileTypes = {'level_up', 'quran_reward', 'quran_khatma'};

  /// Inspects a raw FCM [data] payload and navigates if it recognizes the
  /// `type`. Unknown/missing types are ignored.
  static void routeFromData(Map<String, dynamic> data) {
    if (!profileTypes.contains(data['type'])) return;
    final id = int.tryParse('${data['user_id']}');
    if (id != null) openLevelUpProfile(id);
  }

  /// Opens the profile preview for a friend who just leveled up. Deferred to
  /// after the first frame so it's safe even if called before GetMaterialApp
  /// has finished mounting (e.g. a cold-start tap).
  static void openLevelUpProfile(int userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openProfilePreview(userId);
    });
  }
}
