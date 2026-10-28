import 'dart:async';

import 'package:dio/dio.dart' show CancelToken, DioException, DioExceptionType;
import 'package:get/get.dart';

import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import 'my_world_models.dart';

/// My World: the signed-in user's activity as hotspots on a globe.
///
/// Everything shown is the server's: it decides where each record is placed
/// (and what can't be), clusters them for the zoom level and counts them per
/// category. This controller only holds the filters and asks again when they
/// or the zoom level change — debounced, with any superseded request
/// cancelled so a stale answer never lands over a newer one.
class MyWorldController extends GetxController {
  final _api = Get.find<ApiProvider>();

  /// Selected category ids; all of them to start.
  final selected = <String>{...WorldCategory.ids}.obs;

  /// The server's grid level for the current zoom (0 = whole globe).
  final level = 1.obs;

  final clusters = <WorldCluster>[].obs;
  final meta = Rxn<WorldMeta>();

  final loading = true.obs;

  /// Why the last load failed, translated; null when it didn't.
  final loadError = RxnString();

  CancelToken? _inflight;
  Timer? _debounce;

  static const _debounceDelay = Duration(milliseconds: 350);

  /// Grid level for a globe zoom factor: finer cells as the globe grows.
  static int levelFor(double zoom) {
    if (zoom < 1.0) return 0;
    if (zoom < 1.4) return 1;
    if (zoom < 2.0) return 2;
    if (zoom < 2.8) return 3;
    if (zoom < 4.0) return 4;
    return 5;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _inflight?.cancel();
    super.onClose();
  }

  /// The camera zoomed; asks for the new level's clusters once it settles.
  void onZoom(double zoom) {
    final next = levelFor(zoom);
    if (next == level.value) return;
    level.value = next;
    _schedule();
  }

  void toggleCategory(String id) {
    if (!selected.remove(id)) selected.add(id);
    _schedule();
  }

  void selectAll() {
    if (selected.length == WorldCategory.all.length) return;
    selected.addAll(WorldCategory.ids);
    _schedule();
  }

  /// Back to every category.
  void resetFilters() {
    selected
      ..clear()
      ..addAll(WorldCategory.ids);
    _schedule();
  }

  /// Category ids in the server's order, for a request.
  List<String> get selectedIds => [
    for (final id in WorldCategory.ids)
      if (selected.contains(id)) id,
  ];

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, load);
  }

  Future<void> load() async {
    _debounce?.cancel();
    _inflight?.cancel();

    // Nothing selected matches nothing; no need to ask.
    if (selected.isEmpty) {
      clusters.clear();
      loading.value = false;
      loadError.value = null;
      return;
    }

    final token = _inflight = CancelToken();
    loading.value = true;
    loadError.value = null;
    try {
      final res = await _api.myWorld(categories: selectedIds, level: level.value, cancelToken: token);
      if (token.isCancelled) return;
      clusters.assignAll([
        for (final c in (res['clusters'] as List? ?? const []))
          WorldCluster.fromJson(Map<String, dynamic>.from(c as Map)),
      ]);
      if (res['meta'] is Map) {
        meta.value = WorldMeta.fromJson(Map<String, dynamic>.from(res['meta'] as Map));
      }
    } catch (e, st) {
      if (token.isCancelled || (e is DioException && e.type == DioExceptionType.cancel)) return;
      ErrorReporter.report(e, st);
      loadError.value = messageFor(e);
    } finally {
      if (identical(_inflight, token)) {
        loading.value = false;
        _inflight = null;
      }
    }
  }

  /// A message the user can act on, in their language.
  static String messageFor(Object e) {
    if (e is ApiException) {
      return switch (e.status) {
        401 => 'my_world_error_auth'.tr,
        404 => 'my_world_error_gone'.tr,
        429 => 'my_world_error_too_many'.tr,
        _ => 'my_world_error_server'.tr,
      };
    }
    if (e is DioException && e.response == null) {
      return 'my_world_error_network'.tr;
    }
    if (e is DioException && e.response?.statusCode == 404) {
      return 'my_world_error_gone'.tr;
    }
    return 'my_world_error_server'.tr;
  }
}
