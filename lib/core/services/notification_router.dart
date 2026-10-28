import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/providers/storage_provider.dart';
import '../../modules/adhkar/adhkar_collection_view.dart';
import '../../modules/adhkar/adhkar_store.dart';
import '../../modules/adhkar/adhkar_view.dart';
import '../../modules/profile_preview/profile_preview_modal.dart';

/// Routes a tapped notification to the right screen. Shared by the three
/// paths Firebase/local-notifications can deliver a tap on:
///   * foreground → re-posted locally, tapped → NotificationService._onAction
///   * background (app in memory) → FirebaseMessaging.onMessageOpenedApp
///   * terminated (cold start)     → FirebaseMessaging.instance.getInitialMessage()
class NotificationRouter {
  /// Friend activity whose notification opens that friend's profile: a level
  /// reached, the day's Quran reward taken, a khatma completed, the day's
  /// first صدقة recorded.
  static const profileTypes = {'level_up', 'quran_reward', 'quran_khatma', 'sadaqah'};

  /// Inspects a raw FCM [data] payload and navigates if it recognizes the
  /// `type`. Unknown/missing types are ignored.
  static void routeFromData(Map<String, dynamic> data) {
    if (!profileTypes.contains(data['type'])) return;
    final id = int.tryParse('${data['user_id']}');
    if (id != null) openLevelUpProfile(id);
  }

  /// Payload of the Adhkar & Duas reminders: `adhkar` for a general one,
  /// `adhkar:{collection uid}` for one that opens its collection.
  static const adhkarPayload = 'adhkar';

  static String adhkarPayloadFor(String? collectionUid) =>
      collectionUid == null ? adhkarPayload : '$adhkarPayload:$collectionUid';

  static bool isAdhkarPayload(String? payload) =>
      payload == adhkarPayload || (payload?.startsWith('$adhkarPayload:') ?? false);

  /// A reminder tapped before the home screen was there — the app launched
  /// from it — waiting for [consumePendingAdhkar].
  static String? _pendingAdhkar;

  /// Opens the collection a reminder belongs to, or the Adhkar & Duas page.
  /// Until the signed-in home screen exists (a cold start goes through the
  /// splash and permission screens first), the tap is held and opened from
  /// there, so those screens can't replace it.
  static void openAdhkar(String payload) {
    if (!Get.find<StorageProvider>().isLoggedIn || !_homeReady) {
      _pendingAdhkar = payload;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _openAdhkarNow(payload));
  }

  static bool _homeReady = false;

  /// Called once the home screen is up: opens a reminder tapped at launch.
  static void consumePendingAdhkar() {
    _homeReady = true;
    final payload = _pendingAdhkar;
    _pendingAdhkar = null;
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAdhkarNow(payload));
    }
  }

  static void _openAdhkarNow(String payload) {
    AdhkarView.ensureServices();
    final uid = payload.startsWith('$adhkarPayload:')
        ? payload.substring(adhkarPayload.length + 1)
        : null;
    // From the device's cache: works offline and before the content loads.
    final collection = uid == null ? null : Get.find<AdhkarStore>().findCollection(uid);
    if (collection != null) {
      AdhkarCollectionView.open(collection);
    } else {
      AdhkarView.open();
    }
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
