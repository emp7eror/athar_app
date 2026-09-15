import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

import '../../../core/constants/quran_surahs.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/providers/storage_provider.dart';
import '../quran_ayah_geometry.dart';
import 'recitation_models.dart';

/// Recites the Quran ayah by ayah: plays one ayah's file, then the next, on
/// through the surahs until stopped.
///
/// Reciters come from the server (managed in the admin panel) and are kept on
/// the device. Every ayah played is kept in its own cache, and the next ayah
/// is fetched while the current one plays, so the step between them is quick
/// and a passage once heard plays offline.
class RecitationService extends GetxService {
  static RecitationService get instance => Get.isRegistered<RecitationService>()
      ? Get.find<RecitationService>()
      : Get.put(RecitationService(), permanent: true);

  final _player = AudioPlayer(playerId: 'athar_quran');

  final _cache = CacheManager(
    Config(
      'athar_recitation',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 3000,
    ),
  );

  StorageProvider get _storage => Get.find<StorageProvider>();

  /// The slug the reader chose; empty means the default reciter.
  final selectedSlug = ''.obs;

  /// The ayah being recited, or paused on. Null when nothing is.
  final current = Rxn<AyahRef>();

  final playing = false.obs;

  /// The ayah's audio is being fetched.
  final loading = false.obs;

  /// The ayah couldn't be played (usually no connection).
  final failed = false.obs;

  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;

  List<Reciter>? _reciters;
  Future<List<Reciter>>? _loadingList;

  /// Bumped by every start and stop, so an ayah that finishes loading after
  /// the reader has moved on is dropped.
  int _generation = 0;

  final _subscriptions = <StreamSubscription<dynamic>>[];

  @override
  void onInit() {
    super.onInit();
    selectedSlug.value = _storage.quranReciterSlug ?? '';
    final cached = _parse(_storage.quranRecitersCache);
    if (cached.isNotEmpty) _reciters = cached;

    unawaited(_player.setReleaseMode(ReleaseMode.stop));
    _subscriptions.addAll([
      _player.onPlayerStateChanged.listen((s) => playing.value = s == PlayerState.playing),
      _player.onPositionChanged.listen((p) => position.value = p),
      _player.onDurationChanged.listen((d) => duration.value = d),
      _player.onPlayerComplete.listen((_) {
        if (!loading.value && current.value != null) next();
      }),
    ]);
  }

  @override
  void onClose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    super.onClose();
  }

  // ── Reciters ───────────────────────────────────────────────────────────

  /// Every active reciter, in the server's order. Fetched once per app run;
  /// the copy on the device answers when the server can't.
  Future<List<Reciter>> reciters() {
    return _loadingList ??= _fetch().then((list) {
      _reciters = list;
      return list;
    }).catchError((Object e) {
      _loadingList = null;
      final held = _reciters;
      if (held != null && held.isNotEmpty) return held;
      throw e;
    });
  }

  Future<List<Reciter>> _fetch() async {
    final res = await Get.find<ApiProvider>().quranReciters();
    final list = _parse(res['reciters']);
    if (list.isEmpty) throw StateError('No reciters');
    _storage.quranRecitersCache = [for (final r in list) r.toJson()];
    return list;
  }

  static List<Reciter> _parse(Object? data) => [
        if (data is List)
          for (final item in data)
            if (item is Map) Reciter.fromJson(Map<String, dynamic>.from(item)),
      ].where((r) => r.isValid).toList();

  /// The reciter for [slug] — or the default when none is chosen or the
  /// choice is gone. Null until the list has loaded.
  Reciter? reciterFor(String slug) {
    final list = _reciters;
    if (list == null || list.isEmpty) return null;
    for (final r in list) {
      if (r.slug == slug) return r;
    }
    for (final r in list) {
      if (r.isDefault) return r;
    }
    return list.first;
  }

  Reciter? get reciter => reciterFor(selectedSlug.value);

  /// Remembers the choice, and carries on with the same ayah in the new voice.
  void selectReciter(String slug) {
    selectedSlug.value = slug;
    _storage.quranReciterSlug = slug;
    final ayah = current.value;
    if (ayah != null) unawaited(playFrom(ayah));
  }

  // ── Playback ───────────────────────────────────────────────────────────

  /// Recites from [ayah] on.
  Future<void> playFrom(AyahRef ayah) async {
    final generation = ++_generation;
    current.value = ayah;
    failed.value = false;
    loading.value = true;
    position.value = Duration.zero;
    duration.value = Duration.zero;

    try {
      await _player.stop();
      await reciters();
      final voice = reciter;
      if (voice == null) throw StateError('No reciter');

      final file = await _cache.getSingleFile(voice.audioUrl(ayah.surah, ayah.ayah));
      if (generation != _generation) return;

      await _player.play(DeviceFileSource(file.path));
      if (generation != _generation) return;
      loading.value = false;

      final following = after(ayah);
      if (following != null) {
        unawaited(
          _cache
              .getSingleFile(voice.audioUrl(following.surah, following.ayah))
              .then((_) {}, onError: (Object _) {}),
        );
      }
    } catch (e) {
      if (generation != _generation) return;
      debugPrint('[recitation] $ayah failed: $e');
      loading.value = false;
      failed.value = true;
      playing.value = false;
    }
  }

  /// Pauses, resumes, or — after a failure — tries the ayah again.
  Future<void> togglePlay() async {
    final ayah = current.value;
    if (ayah == null || loading.value) return;

    if (failed.value) {
      await playFrom(ayah);
    } else if (_player.state == PlayerState.playing) {
      await _player.pause();
    } else if (_player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      await playFrom(ayah);
    }
  }

  Future<void> seek(Duration to) => _player.seek(to);

  /// The ayah after the current one; stops after the last ayah of the Quran.
  void next() {
    final ayah = current.value;
    if (ayah == null) return;
    final following = after(ayah);
    if (following == null) {
      stop();
    } else {
      unawaited(playFrom(following));
    }
  }

  void previous() {
    final ayah = current.value;
    if (ayah == null) return;
    final preceding = before(ayah);
    if (preceding != null) unawaited(playFrom(preceding));
  }

  void stop() {
    _generation++;
    unawaited(_player.stop());
    current.value = null;
    playing.value = false;
    loading.value = false;
    failed.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  /// The next ayah in the Mushaf, crossing into the next surah.
  static AyahRef? after(AyahRef a) {
    if (a.surah < 1 || a.surah > kQuranSurahs.length) return null;
    if (a.ayah < kQuranSurahs[a.surah - 1].ayahs) return AyahRef(a.surah, a.ayah + 1);
    if (a.surah < kQuranSurahs.length) return AyahRef(a.surah + 1, 1);
    return null;
  }

  /// The previous ayah in the Mushaf, crossing back into the previous surah.
  static AyahRef? before(AyahRef a) {
    if (a.ayah > 1) return AyahRef(a.surah, a.ayah - 1);
    if (a.surah > 1 && a.surah <= kQuranSurahs.length) {
      return AyahRef(a.surah - 1, kQuranSurahs[a.surah - 2].ayahs);
    }
    return null;
  }
}
