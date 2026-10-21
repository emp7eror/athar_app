import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'adhkar_models.dart';
import 'adhkar_store.dart';

/// Reading one collection: the counters, which item is current, and moving on
/// when an item is complete. The list and the one-at-a-time view both read
/// from here, so they can never disagree.
///
/// - The session (what is current, list or one-at-a-time) lives only while the
///   collection is open.
/// - Today's counts belong to [AdhkarStore], on disk and synced.
/// - Earlier days are history on the server, untouched by anything here.
class AdhkarSession extends GetxController {
  AdhkarSession(this.uid, this._fallback);

  /// The collection's [AdhkarCollection.uid].
  final String uid;
  AdhkarCollection _fallback;

  final store = Get.find<AdhkarStore>();

  /// The item to read next: the first unfinished one with a target, after the
  /// last one completed. -1 when every such item is done (or there are none).
  final current = (-1).obs;

  /// Fires once per completed item with the index moved to, so the views can
  /// scroll or page there. The token makes each event distinct.
  final advance = Rxn<({int index, int token})>();
  int _token = 0;

  /// One item at a time instead of the full list (the reader's own
  /// collections). Both views share these counters.
  final sequential = false.obs;

  /// Taps are ignored for a moment after an item completes, so a fast
  /// double-tap can't count the item that just slid into place.
  DateTime _lockedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  static const _advanceLock = Duration(milliseconds: 450);

  /// The collection as it is now — content may have been edited or reloaded.
  AdhkarCollection get collection {
    final latest = store.findCollection(uid);
    if (latest != null) _fallback = latest;
    return _fallback;
  }

  List<AdhkarItem> get items => collection.items;

  int countOf(AdhkarItem item) => store.count(item.key);

  bool isDone(AdhkarItem item) =>
      item.hasTarget && countOf(item) >= item.target!;

  int get targeted => items.where((i) => i.hasTarget).length;
  int get completed => items.where(isDone).length;

  /// Progress through the items that have a target; items without one can be
  /// read and counted but don't complete.
  double get progress => targeted == 0 ? 0 : completed / targeted;

  bool get allDone => targeted > 0 && completed == targeted;

  @override
  void onInit() {
    super.onInit();
    current.value = _firstUnfinished(after: -1);
    // Counts can change without a tap here — a sync from another device, a
    // reset, a new day. Keep [current] on an unfinished item.
    _worker = ever(store.revision, (_) => _keepCurrentValid());
  }

  late final Worker _worker;

  @override
  void onClose() {
    _worker.dispose();
    super.onClose();
  }

  void _keepCurrentValid() {
    final list = items;
    final i = current.value;
    if (i < 0 || i >= list.length || isDone(list[i]) || !list[i].hasTarget) {
      current.value = _firstUnfinished(after: i < 0 ? -1 : i - 1);
    }
  }

  /// The first unfinished item with a target after [after], coming round to
  /// the start — so nothing unfinished is ever skipped for good.
  int _firstUnfinished({required int after}) {
    final list = items;
    for (var step = 1; step <= list.length; step++) {
      final i = (after + step) % list.length;
      if (list[i].hasTarget && !isDone(list[i])) return i;
    }
    return -1;
  }

  /// Counts one repetition of [item]. Returns false when the tap was ignored
  /// (item already complete, or just after an advance).
  bool increment(AdhkarItem item) {
    if (DateTime.now().isBefore(_lockedUntil)) return false;
    if (isDone(item)) return false;

    final before = countOf(item);
    store.increment(item.key);
    HapticFeedback.selectionClick();

    // Exactly once: only the tap that crosses the target lands here, and the
    // item ignores taps from then on.
    if (item.hasTarget && before + 1 >= item.target!) _completed(item);
    return true;
  }

  void _completed(AdhkarItem item) {
    HapticFeedback.mediumImpact();
    _lockedUntil = DateTime.now().add(_advanceLock);
    final next = _firstUnfinished(
      after: items.indexWhere((i) => i.key == item.key),
    );
    current.value = next;
    if (next >= 0) advance.value = (index: next, token: ++_token);
  }

  /// Makes [index] current by hand (tapping a card's header, paging).
  void focus(int index) {
    if (index >= 0 && index < items.length) current.value = index;
  }

  /// Resets [item] only; every other count stays.
  void resetItem(AdhkarItem item) {
    store.reset([item.key]);
    if (current.value < 0) current.value = _firstUnfinished(after: -1);
  }

  void resetAll() {
    store.reset(items.map((i) => i.key));
    current.value = _firstUnfinished(after: -1);
    if (current.value >= 0) {
      advance.value = (index: current.value, token: ++_token);
    }
  }
}
