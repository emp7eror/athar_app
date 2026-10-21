import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/services/timezone_service.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import 'adhkar_models.dart';

enum AdhkarSyncState { synced, pending, syncing, offline, failed }

/// A failed change to the reader's collections, with a message to show.
class AdhkarActionException implements Exception {
  AdhkarActionException(this.message, {this.offline = false});
  final String message;

  /// The request never reached the server — no connection.
  final bool offline;

  @override
  String toString() => message;
}

/// One counter operation made on the device: add [amount] to an item on a
/// day, or reset it. Sent to the server with its own [opId], so a retry of one
/// the server already applied is recognised and skipped.
class _Op {
  _Op({
    required this.opId,
    required this.key,
    required this.date,
    required this.reset,
    this.amount = 0,
  });

  final String opId;
  final String key;
  final String date;
  final bool reset;
  int amount;

  Map<String, dynamic> toJson() => {
    'op_id': opId,
    'item_key': key,
    'date': date,
    'type': reset ? 'reset' : 'inc',
    if (!reset) 'amount': amount,
  };

  static _Op? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['op_id']?.toString();
    final key = j['item_key']?.toString();
    final date = j['date']?.toString();
    if (id == null || key == null || date == null) return null;
    return _Op(
      opId: id,
      key: key,
      date: date,
      reset: j['type'] == 'reset',
      amount: (j['amount'] as num?)?.round() ?? 0,
    );
  }
}

/// Adhkar & Duas on the device: the content (cached for offline reading) and
/// the counters (counted offline, synced when the connection returns).
///
/// Counting never waits for the network. Each tap is written to disk as an
/// operation before anything else, then sent in batches. What is shown is the
/// server's last confirmed count for the day plus every operation not yet
/// confirmed, so nothing counted is lost when the app closes or the
/// connection drops, and a stale reply can't roll a count back: the server
/// adds operations, it never takes a total from the app.
///
/// Days are the device's calendar days. Earlier days stay on the server as
/// history; locally only the last few are kept.
///
/// Changing collections (create, edit, reorder, delete) needs a connection;
/// those calls fail with [AdhkarActionException] and change nothing locally.
class AdhkarStore extends GetxService with WidgetsBindingObserver {
  final _api = Get.find<ApiProvider>();
  final _storage = Get.find<StorageProvider>();
  final _box = GetStorage();

  static const _maxBatch = 200;
  static const _maxAmount = 1000;
  static const _syncDelay = Duration(seconds: 2);
  static const _retryDelay = Duration(seconds: 30);

  // ── Content ──
  final publicCollections = <AdhkarCollection>[].obs;
  final categories = <AdhkarCollection>[].obs;
  final mine = <AdhkarCollection>[].obs;

  /// Content is on screen — from the cache or the network.
  final contentReady = false.obs;
  final loadingContent = false.obs;

  /// Why content couldn't be loaded, when there is nothing cached to show.
  final contentError = RxnString();

  /// The last request failed for want of a connection.
  final offline = false.obs;

  // ── Progress ──
  /// Bumped whenever a count changes, so views can rebuild.
  final revision = 0.obs;
  final syncState = AdhkarSyncState.synced.obs;
  final pendingOps = 0.obs;

  /// Server-confirmed counts: date → item key → count.
  final _confirmed = <String, Map<String, int>>{};
  final _ops = <_Op>[];
  final _inFlight = <String>{};

  bool _syncing = false;
  Timer? _syncTimer;
  String? _userKey;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _ensureUser();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureUser();
      unawaited(sync());
    } else if (state == AppLifecycleState.paused) {
      // Try to deliver before the OS may suspend us; on disk either way.
      unawaited(sync());
    }
  }

  static String today() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  // ── Per-account storage ───────────────────────────────────────────────

  /// Everything is kept per account, so a second account on the device never
  /// sees the first one's private collections or progress.
  void _ensureUser() {
    final id = _storage.cachedUser?['id']?.toString() ?? 'anon';
    if (id == _userKey) return;
    _userKey = id;
    _syncTimer?.cancel();
    publicCollections.clear();
    categories.clear();
    mine.clear();
    contentReady.value = false;
    contentError.value = null;
    _confirmed.clear();
    _ops.clear();
    _inFlight.clear();
    _readProgress();
    _readContentCache();
    _bump();
  }

  String get _contentKey => 'adhkar_content_$_userKey';
  String get _progressKey => 'adhkar_progress_$_userKey';

  void _readContentCache() {
    final cached = _box.read(_contentKey);
    if (cached is Map) {
      _applyLibrary(cached['library']);
      _applyMine(cached['mine']);
      contentReady.value = true;
    }
  }

  Map<String, dynamic>? _libraryJson;
  List<dynamic>? _mineJson;

  Future<void> _writeContentCache() =>
      _box.write(_contentKey, {'library': _libraryJson, 'mine': _mineJson});

  void _readProgress() {
    final raw = _box.read(_progressKey);
    if (raw is! Map) return;
    final confirmed = raw['confirmed'];
    if (confirmed is Map) {
      confirmed.forEach((date, items) {
        if (items is Map) {
          _confirmed['$date'] = {
            for (final e in items.entries)
              '${e.key}': (e.value as num?)?.round() ?? 0,
          };
        }
      });
    }
    final ops = raw['ops'];
    if (ops is List) {
      _ops.addAll(ops.map(_Op.fromJson).whereType<_Op>());
    }
  }

  /// Written on every change, before anything is sent: a count survives the
  /// app being closed straight after the tap.
  Future<void> _writeProgress() {
    // Only the last few days are needed locally; the server keeps history.
    final keep = _confirmed.keys.toList()..sort();
    while (keep.length > 3) {
      _confirmed.remove(keep.removeAt(0));
    }
    return _box.write(_progressKey, {
      'confirmed': _confirmed,
      'ops': _ops.map((o) => o.toJson()).toList(),
    });
  }

  // ── Content ───────────────────────────────────────────────────────────

  /// Shows the cache at once (if any), then refreshes from the server.
  Future<void> loadContent() async {
    _ensureUser();
    if (loadingContent.value) return;
    loadingContent.value = true;
    try {
      final results = await Future.wait([
        _api.adhkarLibrary(),
        _api.adhkarMine(),
      ]);
      _applyLibrary(results[0]);
      _applyMine(results[1]['collections']);
      await _writeContentCache();
      contentReady.value = true;
      contentError.value = null;
      offline.value = false;
      unawaited(refreshProgress());
    } catch (e) {
      final noConnection = e is DioException;
      offline.value = noConnection;
      if (!noConnection) ErrorReporter.report(e, StackTrace.current);
      if (!contentReady.value) {
        contentError.value = noConnection
            ? 'adhkar_offline_no_cache'.tr
            : 'adhkar_load_failed'.tr;
      }
    } finally {
      loadingContent.value = false;
    }
  }

  void _applyLibrary(Object? json) {
    if (json is! Map) return;
    _libraryJson = Map<String, dynamic>.from(json);
    final collections = json['collections'];
    final cats = json['categories'];
    publicCollections.assignAll([
      if (collections is List)
        for (final c in collections)
          if (c is Map)
            AdhkarCollection.publicFromJson(Map<String, dynamic>.from(c)),
    ]);
    categories.assignAll([
      if (cats is List)
        for (final c in cats)
          if (c is Map)
            AdhkarCollection.categoryFromJson(Map<String, dynamic>.from(c)),
    ]);
  }

  void _applyMine(Object? json) {
    if (json is! List) return;
    _mineJson = json;
    mine.assignAll([
      for (final c in json)
        if (c is Map)
          AdhkarCollection.personalFromJson(Map<String, dynamic>.from(c)),
    ]);
  }

  List<DuaCategory> get duaCategories => [
    for (final c in categories)
      DuaCategory(id: c.id, nameAr: c.nameAr, nameEn: c.nameEn),
  ];

  AdhkarCollection? findCollection(String uid) {
    for (final list in [publicCollections, categories, mine]) {
      for (final c in list) {
        if (c.uid == uid) return c;
      }
    }
    return null;
  }

  // ── Counters ──────────────────────────────────────────────────────────

  /// Today's count for [key]: confirmed by the server, plus what the device
  /// counted since.
  int count(String key) {
    final day = today();
    var n = _confirmed[day]?[key] ?? 0;
    for (final op in _ops) {
      if (op.key != key || op.date != day) continue;
      n = op.reset ? 0 : n + op.amount;
    }
    return n;
  }

  /// Counts one repetition. Written to disk at once; sent shortly after.
  void increment(String key) {
    final day = today();
    final last = _ops.isEmpty ? null : _ops.last;
    // Taps in a row on one item travel as one operation — unless that one
    // is already on its way, in which case it must stay as sent.
    if (last != null &&
        !last.reset &&
        last.key == key &&
        last.date == day &&
        !_inFlight.contains(last.opId) &&
        last.amount < _maxAmount) {
      last.amount++;
    } else {
      _ops.add(
        _Op(opId: _newOpId(), key: key, date: day, reset: false, amount: 1),
      );
    }
    _changed();
  }

  /// Sets today's count of each of [keys] back to zero.
  void reset(Iterable<String> keys) {
    final day = today();
    for (final key in keys) {
      if (count(key) == 0) continue;
      _ops.add(_Op(opId: _newOpId(), key: key, date: day, reset: true));
    }
    _changed();
  }

  void _changed() {
    unawaited(_writeProgress());
    _bump();
    _scheduleSync(_syncDelay);
  }

  void _bump() {
    pendingOps.value = _ops.length;
    if (!_syncing) {
      syncState.value = _ops.isEmpty
          ? AdhkarSyncState.synced
          : (offline.value ? AdhkarSyncState.offline : AdhkarSyncState.pending);
    }
    revision.value++;
  }

  static final _random = Random.secure();

  static String _newOpId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = List.generate(
      12,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$rand';
  }

  void _scheduleSync(Duration after) {
    _syncTimer?.cancel();
    _syncTimer = Timer(after, () => unawaited(sync()));
  }

  Future<String> get _tz => Get.find<TimezoneService>().resolve();

  /// Sends what was counted on the device. Safe to call any time: one batch
  /// at a time, and every operation keeps its id across retries.
  Future<void> sync() async {
    // Another account may have signed in since: its ops are its own, and the
    // previous account's stay on disk under that account.
    _ensureUser();
    if (_syncing || _ops.isEmpty || !_storage.isLoggedIn) return;
    _syncing = true;
    syncState.value = AdhkarSyncState.syncing;

    final batch = _ops.take(_maxBatch).toList();
    _inFlight.addAll(batch.map((o) => o.opId));
    var retryLater = false;
    try {
      final res = await _api.adhkarSync(
        batch.map((o) => o.toJson()).toList(),
        await _tz,
      );
      // Every op in the batch is settled — applied, already applied, or
      // refused for good — and the reply carries the day's totals with them.
      final sent = batch.map((o) => o.opId).toSet();
      _ops.removeWhere((o) => sent.contains(o.opId));
      _applyDay(res);
      offline.value = false;
    } on DioException catch (_) {
      offline.value = true;
      retryLater = true;
    } on ApiException catch (e) {
      if (e.status == 429 || e.status == 401) {
        retryLater = true;
      } else {
        // Rejected as a whole (malformed): resending can never succeed, and
        // keeping it would block everything counted after it.
        ErrorReporter.report(e, StackTrace.current);
        final sent = batch.map((o) => o.opId).toSet();
        _ops.removeWhere((o) => sent.contains(o.opId));
        syncState.value = AdhkarSyncState.failed;
      }
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      retryLater = true;
    } finally {
      _inFlight.clear();
      _syncing = false;
    }

    await _writeProgress();
    final failed = syncState.value == AdhkarSyncState.failed;
    _bump();
    if (failed) syncState.value = AdhkarSyncState.failed;
    if (retryLater) {
      _scheduleSync(_retryDelay);
    } else if (_ops.isNotEmpty) {
      _scheduleSync(Duration.zero);
    }
  }

  void _applyDay(Map<String, dynamic> res) {
    final day = res['today']?.toString() ?? today();
    final items = res['items'];
    _confirmed[day] = {
      if (items is Map)
        for (final e in items.entries)
          if (e.value is Map)
            '${e.key}': ((e.value as Map)['count'] as num?)?.round() ?? 0,
    };
  }

  /// Today's counts from the server — after delivering anything pending, so
  /// the reply already includes it.
  Future<void> refreshProgress() async {
    _ensureUser();
    if (_ops.isNotEmpty) {
      await sync();
      return; // the sync reply carries today's counts
    }
    if (_syncing) return;
    _syncing = true;
    try {
      final res = await _api.adhkarProgress(await _tz);
      // Counted while the request was out: still in _ops, still applied on top.
      _applyDay(res);
      offline.value = false;
      await _writeProgress();
    } on DioException catch (_) {
      offline.value = true;
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    } finally {
      _syncing = false;
      _bump();
    }
  }

  // ── Managing the reader's own collections (online only) ──────────────

  Future<Map<String, dynamic>> _guard(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    try {
      final res = await call();
      offline.value = false;
      return res;
    } on DioException catch (_) {
      offline.value = true;
      throw AdhkarActionException('adhkar_needs_internet'.tr, offline: true);
    } on ApiException catch (e) {
      throw AdhkarActionException(
        e.message.isNotEmpty ? e.message : 'adhkar_action_failed'.tr,
      );
    }
  }

  /// Puts a collection from a server reply into [mine], replacing the old copy.
  AdhkarCollection _storeMine(Map<String, dynamic> res) {
    final json = Map<String, dynamic>.from(res['collection'] as Map);
    final collection = AdhkarCollection.personalFromJson(json);
    final list = List<dynamic>.from(_mineJson ?? const []);
    final at = list.indexWhere((c) => c is Map && c['id'] == json['id']);
    if (at >= 0) {
      list[at] = json;
    } else {
      list.add(json);
    }
    _applyMine(list);
    unawaited(_writeContentCache());
    return collection;
  }

  Future<AdhkarCollection> createCollection({
    required AdhkarType type,
    required String name,
    String? description,
    String? icon,
    int? categoryId,
  }) async => _storeMine(
    await _guard(
      () => _api.adhkarCreateCollection({
        'type': type.name,
        'name': name,
        'description': description,
        'icon': icon,
        'category_id': categoryId,
      }),
    ),
  );

  Future<AdhkarCollection> copyCollection(AdhkarCollection source) async =>
      _storeMine(
        await _guard(
          () => source.source == AdhkarSource.publicCategory
              ? _api.adhkarCopyCollection(categoryId: source.id)
              : _api.adhkarCopyCollection(collectionId: source.id),
        ),
      );

  Future<AdhkarCollection> updateCollection(
    AdhkarCollection collection, {
    required String name,
    String? description,
    String? icon,
    int? categoryId,
  }) async => _storeMine(
    await _guard(
      () => _api.adhkarUpdateCollection(collection.id, {
        'name': name,
        'description': description,
        'icon': icon,
        'category_id': categoryId,
      }),
    ),
  );

  Future<void> deleteCollection(AdhkarCollection collection) async {
    await _guard(() => _api.adhkarDeleteCollection(collection.id));
    final list = List<dynamic>.from(_mineJson ?? const [])
      ..removeWhere((c) => c is Map && c['id'] == collection.id);
    _applyMine(list);
    unawaited(_writeContentCache());
  }

  Future<AdhkarCollection> reorder(
    AdhkarCollection collection,
    List<int> itemIds,
  ) async => _storeMine(
    await _guard(() => _api.adhkarReorder(collection.id, itemIds)),
  );

  Future<AdhkarCollection> addItem(
    AdhkarCollection collection,
    Map<String, dynamic> fields,
  ) async =>
      _storeMine(await _guard(() => _api.adhkarAddItem(collection.id, fields)));

  /// Copies of [items] (public ones) into [into], in this order, all at once.
  Future<AdhkarCollection> copyItems(
    AdhkarCollection into,
    List<AdhkarItem> items,
  ) async => _storeMine(
    await _guard(
      () => _api.adhkarAddItem(into.id, {
        'source_item_ids': [for (final i in items) i.id],
      }),
    ),
  );

  Future<AdhkarCollection> updateItem(
    AdhkarItem item,
    Map<String, dynamic> fields,
  ) async =>
      _storeMine(await _guard(() => _api.adhkarUpdateItem(item.id, fields)));

  Future<AdhkarCollection> deleteItem(AdhkarItem item) async =>
      _storeMine(await _guard(() => _api.adhkarDeleteItem(item.id)));
}
