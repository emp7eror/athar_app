import 'package:dio/dio.dart' show DioException;
import 'package:get/get.dart';

import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import '../home/home_controller.dart';
import 'sadaqah_models.dart';

/// What recording a deed came to, as the server decided it.
class SadaqahRecordResult {
  const SadaqahRecordResult({
    required this.pointsAwarded,
    required this.response,
  });

  /// The deed's points when it was the day's first sadaqah; 0 when today's
  /// points were already taken.
  final int pointsAwarded;

  /// The raw response — the new balance and level, for Home.
  final Map<String, dynamic> response;
}

/// Recording failed; [message] is translated and safe to show.
class SadaqahRecordException implements Exception {
  const SadaqahRecordException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// صدقة: the catalog from the server and what was recorded today. Deeds can
/// be recorded as often as they are done; only the day's first earns points.
/// Points are never computed here — only what the server returns is shown.
class SadaqahController extends GetxController {
  final _api = Get.find<ApiProvider>();

  final categories = <SadaqahCategory>[].obs;
  final deeds = <SadaqahDeed>[].obs;

  final loading = true.obs;

  /// Why the catalog couldn't load, already translated; null when it did.
  final loadError = RxnString();

  /// Deed ids recorded today, in the user's day as the server counts it.
  final recordedToday = <int>{}.obs;

  /// Points today's sadaqah earned, and whether they're taken yet.
  final pointsToday = 0.obs;
  final rewardedToday = false.obs;

  /// The user's totals; null until the first load.
  final stats = Rxn<SadaqahStats>();

  /// The deed being recorded right now. While set, every other attempt is
  /// ignored, so a double tap sends one request.
  final recording = RxnInt();

  /// [key]'s deeds, in the catalog's order.
  List<SadaqahDeed> deedsOf(String key) =>
      deeds.where((d) => d.category == key).toList();

  SadaqahCategory? categoryOf(SadaqahDeed deed) =>
      categories.firstWhereOrNull((c) => c.key == deed.category);

  bool isRecorded(int deedId) => recordedToday.contains(deedId);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void>? _loading;

  /// Loads the catalog and today. Concurrent calls share one request — Home's
  /// first refresh and this controller's own start both ask for it.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    // Keeps what's shown on a refresh; the skeleton is for the first load.
    loading.value = deeds.isEmpty;
    loadError.value = null;
    try {
      final res = await _api.sadaqah();
      categories.assignAll([
        for (final c in (res['categories'] as List? ?? const []))
          SadaqahCategory.fromJson(Map<String, dynamic>.from(c as Map)),
      ]);
      deeds.assignAll([
        for (final d in (res['deeds'] as List? ?? const []))
          SadaqahDeed.fromJson(Map<String, dynamic>.from(d as Map)),
      ]);
      _applyToday(res['today']);
      _applyStats(res['stats']);
    } catch (e, st) {
      ErrorReporter.report(e, st);
      if (deeds.isEmpty) loadError.value = _messageFor(e);
    } finally {
      loading.value = false;
    }
  }

  /// Records [deed] for the signed-in user (تصدقت). Returns the server's
  /// result, or null when another deed is still being recorded. Throws a
  /// [SadaqahRecordException] on failure — nothing is updated then.
  Future<SadaqahRecordResult?> record(SadaqahDeed deed) async {
    if (recording.value != null) return null;
    recording.value = deed.id;
    try {
      final res = await _api.sadaqahRecord(deed.id);
      _applyToday(res['today']);
      _applyStats(res['stats']);
      // The new balance comes from the server, never from adding up here.
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().applyPointsAward(res);
      }
      return SadaqahRecordResult(
        pointsAwarded: (res['points_awarded'] as num?)?.toInt() ?? 0,
        response: res,
      );
    } catch (e, st) {
      ErrorReporter.report(e, st);
      throw SadaqahRecordException(_messageFor(e));
    } finally {
      recording.value = null;
    }
  }

  void _applyToday(dynamic today) {
    if (today is! Map) return;
    recordedToday
      ..clear()
      ..addAll([
        for (final id in (today['deed_ids'] as List? ?? const []))
          (id as num).toInt(),
      ]);
    pointsToday.value = (today['points_today'] as num?)?.toInt() ?? 0;
    rewardedToday.value = today['rewarded'] == true;
  }

  void _applyStats(dynamic json) {
    if (json is Map) {
      stats.value = SadaqahStats.fromJson(Map<String, dynamic>.from(json));
    }
  }

  /// A message the user can act on, in their language.
  static String _messageFor(Object e) {
    if (e is ApiException) {
      return switch (e.status) {
        401 => 'sadaqah_error_auth'.tr,
        404 => 'sadaqah_error_not_found'.tr,
        429 => 'sadaqah_error_too_many'.tr,
        _ => 'sadaqah_error_server'.tr,
      };
    }
    if (e is DioException && e.response == null) {
      return 'sadaqah_error_network'.tr;
    }
    return 'sadaqah_error_server'.tr;
  }
}
