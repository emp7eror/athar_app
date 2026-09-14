import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/services/timezone_service.dart';
import '../../core/tour/tour_service.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/dhikr_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../level_up/level_up_popup.dart';
import 'shake_detector.dart';

/// Tasbeeh / istighfar counters.
///
/// Counting is entirely local and persisted on the device — tapping never
/// touches the network. The server is called once, when the local count reaches
/// the daily target, and it is still the server that accumulates its own total
/// and decides whether the reward is due, so a retry or a restart can't award
/// the points twice.
///
/// Anything counted past the target is flushed when the user leaves the page,
/// purely to keep the stored total honest — it carries no reward.
class DhikrController extends GetxController with WidgetsBindingObserver {
  DhikrController();

  static const tasbeeh = 'tasbeeh';
  static const istighfar = 'istighfar';
  static const keys = [tasbeeh, istighfar];

  /// Must stay at or under the server's MAX_INCREMENTS_PER_REQUEST, or the
  /// request is rejected and the batch retries forever.
  static const _maxBatch = 100;

  /// Taps closer together than this are treated as frantic rather than mindful.
  static const _rapidTapThreshold = Duration(milliseconds: 500);
  static const _rapidTapsBeforeNudge = 5;
  static const _nudgeCooldown = Duration(seconds: 20);

  /// How long the counter stops accepting taps once a frantic run is detected,
  /// so a stuck thumb or an accidental flurry can't inflate the count.
  static const cooldownDuration = Duration(seconds: 2);

  final _api = Get.find<ApiProvider>();
  final _storage = Get.find<StorageProvider>();

  final selected = tasbeeh.obs;
  final loading = true.obs;
  final failed = false.obs;

  /// What the server has confirmed, and what has been counted since.
  final _synced = <String, int>{tasbeeh: 0, istighfar: 0};
  final _pending = <String, int>{tasbeeh: 0, istighfar: 0}.obs;

  final rewarded = <String, bool>{tasbeeh: false, istighfar: false}.obs;

  final target = 100.obs;
  final rewardPoints = 20.obs;

  /// True while taps are being ignored after a frantic run.
  final cooldown = false.obs;

  /// Count by shaking the phone as well as tapping. Remembered on the device.
  final shakeEnabled = false.obs;

  /// Bumped for every shake that was counted, so the strand plays the same
  /// bead animation a tap does.
  final shakeStrikes = 0.obs;

  final _shake = ShakeDetector();
  bool _appActive = true;

  final _syncing = <String, bool>{};
  Timer? _cooldownTimer;

  String _dayKey = '';
  DateTime? _lastTapAt;
  int _rapidTaps = 0;
  DateTime? _lastNudgeAt;
  bool _levelUpShowing = false;

  /// What the user sees: confirmed total plus everything counted locally.
  int countOf(String key) => (_synced[key] ?? 0) + (_pending[key] ?? 0);

  bool isRewarded(String key) => rewarded[key] ?? false;

  /// 0..1 toward the daily target; stays at 1 once the target is passed.
  double progressOf(String key) {
    final t = target.value;
    if (t <= 0) return 0;
    return (countOf(key) / t).clamp(0.0, 1.0);
  }

  int remainingOf(String key) {
    final left = target.value - countOf(key);
    return left > 0 ? left : 0;
  }

  @override
  void onInit() {
    super.onInit();
    shakeEnabled.value = _storage.dhikrShakeEnabled;
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _shake.stop();
    _cooldownTimer?.cancel();
    // Counted-past-the-target taps are sent as the page closes so the stored
    // total matches what the user actually did. Fire-and-forget: nothing here
    // affects the reward, and the queue is on disk if it doesn't land.
    // If the page sat open across midnight, the queue belongs to the day that
    // closed — not to today.
    final closed = _dayKey.isNotEmpty && _dayKey != _localToday;

    for (final key in keys) {
      final n = _pending[key] ?? 0;
      if (n <= 0) continue;
      unawaited(closed ? _sendBatch(key, n, date: _dayKey) : _flush(key));
    }

    _persistPending();
    super.onClose();
  }

  Future<String> get _tz => Get.find<TimezoneService>().resolve();

  Future<void> load() async {
    loading.value = true;
    failed.value = false;
    try {
      final res = await _api.dhikrToday(await _tz);
      final day = DhikrDay.fromJson(res);

      _dayKey = day.date;
      if (day.target > 0) target.value = day.target;
      if (day.rewardPoints > 0) rewardPoints.value = day.rewardPoints;

      for (final item in day.items) {
        _synced[item.key] = item.count;
        rewarded[item.key] = item.rewardGranted;
      }

      _restorePending();

      // A queue left from a previous session may already complete the target.
      for (final key in keys) {
        if ((_pending[key] ?? 0) > 0 && _shouldSend(key)) _flush(key);
      }
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      failed.value = true;
    } finally {
      loading.value = false;
      _syncShakeListening();
    }
  }

  // ── Shake to count ─────────────────────────────────────────────────────

  void toggleShake() {
    shakeEnabled.toggle();
    _storage.dhikrShakeEnabled = shakeEnabled.value;
    HapticFeedback.selectionClick();
    if (shakeEnabled.value) {
      AppSnackbar.show('dhikr_shake_on'.tr, 'dhikr_shake_hint'.tr);
    }
    _syncShakeListening();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncShakeListening();
  }

  /// The sensor only runs while shake counting is on, the counters have
  /// loaded, and the app is in the foreground — never in the background.
  void _syncShakeListening() {
    final listen = shakeEnabled.value &&
        _appActive &&
        !loading.value &&
        !failed.value &&
        !isClosed;
    if (listen) {
      _shake.start(onShake: _onShake, onUnavailable: _onShakeUnavailable);
    } else {
      _shake.stop();
    }
  }

  void _onShake() {
    // A product tour is covering the counter — not a moment to count.
    if (Get.isRegistered<TourService>() &&
        Get.find<TourService>().running.value != null) {
      return;
    }
    // Same path as a tap: cooldown, midnight rollover, reward and sync all apply.
    if (tap(viaShake: true)) shakeStrikes.value++;
  }

  void _onShakeUnavailable() {
    shakeEnabled.value = false;
    _storage.dhikrShakeEnabled = false;
    _shake.stop();
    AppSnackbar.error('dhikr_title'.tr, 'dhikr_shake_unavailable'.tr);
  }

  /// One tap on the active dhikr. Local only, unless this is the tap that
  /// completes the daily target.
  ///
  /// Returns false when the tap was ignored, so the view can skip the haptic
  /// and the bead animation rather than acknowledging something that didn't
  /// count.
  ///
  /// [viaShake] marks a count from shaking the phone: it gets a stronger
  /// vibration, since the user isn't looking at the screen.
  bool tap({bool viaShake = false}) {
    if (cooldown.value) return false;

    // A frantic run stops the count here — the offending tap isn't recorded.
    if (_registerTapPace()) return false;

    // Counting through midnight: close out the finished day before this tap is
    // added, so it lands on the new day's counter rather than the old one.
    _rolloverIfNeeded();

    final key = selected.value;

    viaShake ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();

    _pending[key] = (_pending[key] ?? 0) + 1;
    _pending.refresh();
    _persistPending();

    if (_shouldSend(key)) _flush(key);
    return true;
  }

  /// The single trigger for a network call: the target has been reached and the
  /// reward for this dhikr hasn't been granted yet.
  bool _shouldSend(String key) =>
      !isRewarded(key) && countOf(key) >= target.value;

  void select(String key) => selected.value = key;

  /// Records the pace of this tap. Returns true when the run was frantic enough
  /// to pause counting, in which case the caller must discard the tap.
  bool _registerTapPace() {
    final now = DateTime.now();
    final last = _lastTapAt;
    _lastTapAt = now;

    if (last == null || now.difference(last) > _rapidTapThreshold) {
      _rapidTaps = 0;
      return false;
    }

    _rapidTaps++;
    if (_rapidTaps < _rapidTapsBeforeNudge) return false;

    _rapidTaps = 0;
    _startCooldown();
    return true;
  }

  void _startCooldown() {
    cooldown.value = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(cooldownDuration, () {
      if (!isClosed) cooldown.value = false;
    });

    // The message is throttled separately — the pause repeats as often as
    // needed, but the words shouldn't pile up.
    final now = DateTime.now();
    final lastNudge = _lastNudgeAt;
    if (lastNudge != null && now.difference(lastNudge) < _nudgeCooldown) return;

    _lastNudgeAt = now;
    AppSnackbar.show('dhikr_slow_down_title'.tr, 'dhikr_slow_down_msg'.tr);
  }

  /// Today's date as the counter sees it. The device's local day matches the
  /// pinned timezone the server uses in normal operation.
  String get _localToday {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Sends the finished day's closing count and starts the new day at zero.
  void _rolloverIfNeeded() {
    final today = _localToday;
    if (_dayKey.isEmpty || today == _dayKey) return;

    final closing = _dayKey;
    for (final key in keys) {
      final n = _pending[key] ?? 0;
      if (n > 0) unawaited(_sendBatch(key, n, date: closing));
    }

    _dayKey = today;
    for (final key in keys) {
      _synced[key] = 0;
      _pending[key] = 0;
      rewarded[key] = false;
    }
    _pending.refresh();
    _storage.dhikrPending = {};
  }

  /// Posts [count] increments for [key], splitting anything larger than one
  /// request allows. Used for a day that has already closed, so it doesn't
  /// touch the live counter state.
  Future<void> _sendBatch(String key, int count, {String? date}) async {
    var remaining = count;

    while (remaining > 0) {
      final batch = remaining > _maxBatch ? _maxBatch : remaining;
      try {
        final res = await _api.dhikrIncrement(
          dhikr: key,
          increments: batch,
          timezone: await _tz,
          date: date,
        );
        remaining -= batch;

        final awarded = (res['points_awarded'] as num?)?.round() ?? 0;
        if (awarded > 0) _onRewardGranted(res, awarded);
      } catch (e) {
        ErrorReporter.report(e, StackTrace.current);
        return; // A closed day isn't retried indefinitely.
      }
    }
  }

  /// Sends the locally counted taps for [key]. The batch leaves the queue only
  /// after the server accepts it, so a failure re-sends rather than loses it.
  Future<void> _flush(String key) async {
    if (_syncing[key] == true) return;

    final queued = _pending[key] ?? 0;
    if (queued <= 0) return;

    final batch = queued > _maxBatch ? _maxBatch : queued;

    _syncing[key] = true;
    try {
      final res = await _api.dhikrIncrement(
        dhikr: key,
        increments: batch,
        timezone: await _tz,
      );

      _pending[key] = (_pending[key] ?? 0) - batch;
      if (_pending[key]! < 0) _pending[key] = 0;
      _pending.refresh();
      _persistPending();

      _synced[key] = (res['count'] as num?)?.round() ?? _synced[key] ?? 0;
      rewarded[key] = res['reward_granted'] == true;

      final awarded = (res['points_awarded'] as num?)?.round() ?? 0;
      if (awarded > 0) _onRewardGranted(res, awarded);

      // A queue larger than one request's worth finishes here.
      if ((_pending[key] ?? 0) > 0) unawaited(_flush(key));
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      // Keep the batch queued; it retries on the next qualifying tap, on the
      // next page open, or when the page closes.
    } finally {
      _syncing[key] = false;
    }
  }

  void _onRewardGranted(Map<String, dynamic> res, int awarded) {
    _syncCachedUser(res);

    // Deliberately a snackbar, not a popup — the point is to stay out of the
    // way so the user can keep going.
    AppSnackbar.show(
      'dhikr_reward_title'.trParams({'points': '$awarded'}),
      'dhikr_reward_msg'.tr,
    );

    _maybeShowLevelUp(res);
  }

  /// Keeps the cached user's points/level in step, the same way the prayer flow
  /// does, so Home and Profile don't show a stale total.
  void _syncCachedUser(Map<String, dynamic> res) {
    final cached = _storage.cachedUser;
    if (cached == null) return;

    final updated = Map<String, dynamic>.from(cached);
    if (res['total_points'] != null) updated['total_points'] = res['total_points'];
    if (res['score'] != null) updated['score'] = res['score'];
    if (res['level'] is Map) updated['level'] = res['level'];
    _storage.cachedUser = updated;
  }

  Future<void> _maybeShowLevelUp(Map<String, dynamic> res) async {
    if (res['level_changed'] != true || _levelUpShowing) return;
    final newLevelJson = res['new_level'];
    if (newLevelJson is! Map) return;

    final cached = _storage.cachedUser;
    _levelUpShowing = true;
    try {
      await LevelUpPopup.show(
        name: (cached?['name'] as String?) ?? '',
        avatarUrl: cached?['avatar_url'] as String?,
        newLevel: LevelInfo.fromJson(Map<String, dynamic>.from(newLevelJson)),
        totalPoints: (res['total_points'] as num?)?.round() ?? 0,
      );
    } finally {
      _levelUpShowing = false;
    }
  }

  // ── Local persistence ──────────────────────────────────────────────────

  void _persistPending() {
    final total = keys.fold<int>(0, (sum, k) => sum + (_pending[k] ?? 0));
    if (total == 0) {
      _storage.dhikrPending = {};
      return;
    }
    _storage.dhikrPending = {
      'date': _dayKey,
      for (final k in keys) k: _pending[k] ?? 0,
    };
  }

  void _restorePending() {
    final saved = _storage.dhikrPending;
    if (saved.isEmpty) return;

    final savedDate = saved['date']?.toString() ?? '';

    // The counter resets daily, so a queue from an earlier day can't be added
    // to today's total — but it isn't discarded either. It's sent for the day
    // it belongs to, so the final value of that day is recorded (and its reward
    // still granted if the target was reached before the rollover).
    if (savedDate != _dayKey) {
      _flushStaleDay(saved, savedDate);
      _storage.dhikrPending = {};
      return;
    }

    for (final k in keys) {
      final n = (saved[k] as num?)?.round() ?? 0;
      if (n > 0) _pending[k] = n;
    }
    _pending.refresh();
  }

  /// Delivers the closing count of a day that has already rolled over. The
  /// server only accepts today or yesterday, so anything older is dropped
  /// rather than retried forever.
  void _flushStaleDay(Map<String, dynamic> saved, String date) {
    if (date.isEmpty) return;

    for (final k in keys) {
      final n = (saved[k] as num?)?.round() ?? 0;
      if (n > 0) unawaited(_sendBatch(k, n, date: date));
    }
  }
}
