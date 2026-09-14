import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/providers/storage_provider.dart';
import 'tour_models.dart';
import 'tour_overlay.dart';

/// Runs product tours (coach marks) and remembers which pages' tours the user
/// has already seen.
///
/// * Pages mark elements with `TourTarget(id: …)`; this service keeps the
///   registry so a step can find its element by id.
/// * `maybeStart` shows a page's tour the first time it's visited;
///   `start(replay: true)` replays it from the Help (?) button.
/// * Completion is stored per user and per page, so replaying one page never
///   touches another page's state.
class TourService extends GetxService {
  TourService(Iterable<PageTour> tours)
      : _tours = {for (final t in tours) t.pageId: t};

  final Map<String, PageTour> _tours;
  final _targets = <String, State>{};

  StorageProvider get _storage => Get.find<StorageProvider>();

  /// Page id of the tour on screen, or null.
  final running = RxnString();

  /// The shell tab currently selected (set by `TourTabAutoStart`).
  final activeTab = RxnString();

  Future<void> Function(String pageId)? _tabNavigator;

  // ── Targets ────────────────────────────────────────────────────────

  void register(String id, State state) => _targets[id] = state;

  void unregister(String id, State state) {
    if (identical(_targets[id], state)) _targets.remove(id);
  }

  /// The mounted element registered under [id], if any.
  BuildContext? contextFor(String id) {
    final state = _targets[id];
    return state != null && state.mounted ? state.context : null;
  }

  // ── Navigation between tabs (for steps with `navigateTo`) ─────────

  void setTabNavigator(Future<void> Function(String pageId)? navigator) =>
      _tabNavigator = navigator;

  /// Switches to [pageId]'s tab. Returns false when there's no tab for it.
  Future<bool> navigateTo(String pageId) async {
    final navigator = _tabNavigator;
    if (navigator == null) return false;
    await navigator(pageId);
    return true;
  }

  // ── Tours ──────────────────────────────────────────────────────────

  bool hasTour(String pageId) => _tours[pageId]?.steps.isNotEmpty ?? false;

  String get _userKey => '${_storage.cachedUser?['id'] ?? 'device'}';

  bool isCompleted(String pageId) =>
      _storage.completedTours(_userKey).contains(pageId);

  /// Shows [pageId]'s tour if this user hasn't completed or skipped it yet.
  /// Never runs before login.
  Future<void> maybeStart(String pageId, BuildContext context) async {
    if (!_storage.isLoggedIn || !hasTour(pageId) || isCompleted(pageId)) return;
    await start(pageId, context);
  }

  /// Shows [pageId]'s tour now. [replay] skips the settle delay (the user
  /// asked for it) — the outcome is saved the same way either way.
  Future<void> start(
    String pageId,
    BuildContext context, {
    bool replay = false,
  }) async {
    final tour = _tours[pageId];
    if (tour == null || tour.steps.isEmpty || running.value != null) return;

    running.value = pageId;
    try {
      if (!await _waitUntilReady(tour, context, replay: replay)) return;
      if (!context.mounted) return;

      final outcome = await Navigator.of(context, rootNavigator: true)
          .push<TourOutcome>(TourRoute(tour: tour, service: this));

      if (outcome == TourOutcome.completed || outcome == TourOutcome.skipped) {
        _storage.markTourCompleted(_userKey, pageId);
      }
    } finally {
      running.value = null;
    }
  }

  bool _isVisible(PageTour tour) =>
      !tour.isTab || activeTab.value == tour.pageId;

  /// Waits for the page to settle and for anything covering it (a dialog, a
  /// popup, a bottom sheet) to close. Gives up if the user leaves the page.
  Future<bool> _waitUntilReady(
    PageTour tour,
    BuildContext context, {
    required bool replay,
  }) async {
    if (!replay) await Future<void>.delayed(const Duration(milliseconds: 700));

    for (var attempt = 0; attempt < 120; attempt++) {
      if (!context.mounted || !_isVisible(tour)) return false;
      final onTop = ModalRoute.of(context)?.isCurrent ?? true;
      if (onTop) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }
}
