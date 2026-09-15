import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../../data/providers/storage_provider.dart';
import 'tafsir_models.dart';

/// Tafsir editions come from the server (`GET /quran/tafsirs`, managed in the
/// admin panel); each names the folder its files live in, in the
/// spa5k/tafsir_api layout:
///   `{edition.url}/{surah}/{ayah}.json`   → `{"text", "surah", "ayah"}`
///
/// The list is kept on the device for offline use, and every file read is
/// kept in its own cache, so a tafsir once opened reads offline afterwards.
class TafsirService extends GetxService {
  /// How far back to look for a text shared by a group of ayahs.
  static const _maxLookBack = 12;

  /// Registered on first use.
  static TafsirService get instance => Get.isRegistered<TafsirService>()
      ? Get.find<TafsirService>()
      : Get.put(TafsirService(), permanent: true);

  /// Its own cache, apart from the page images: tafsir files are small and
  /// many, and should stay readable offline for a long time.
  final _cache = CacheManager(
    Config(
      'athar_tafsir',
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 5000,
    ),
  );

  StorageProvider get _storage => Get.find<StorageProvider>();

  /// The slug the reader chose; empty until they choose, which means the
  /// default edition for the app's language.
  final selectedSlug = ''.obs;

  List<TafsirEdition>? _editions;
  Future<List<TafsirEdition>>? _loading;
  final _ayahMemo = <String, AyahTafsir?>{};

  @override
  void onInit() {
    super.onInit();
    selectedSlug.value = _storage.quranTafsirSlug ?? '';
    // Usable at once offline; refreshed from the server on first need.
    final cached = _parse(_storage.quranTafsirsCache);
    if (cached.isNotEmpty) _editions = cached;
  }

  void select(String slug) {
    selectedSlug.value = slug;
    _storage.quranTafsirSlug = slug;
  }

  /// Every active edition, in the server's order. Fetched once per app run;
  /// the copy on the device answers when the server can't.
  Future<List<TafsirEdition>> editions() {
    return _loading ??= _fetch().then((list) {
      _editions = list;
      return list;
    }).catchError((Object e) {
      _loading = null;
      final held = _editions;
      if (held != null && held.isNotEmpty) return held;
      throw e;
    });
  }

  Future<List<TafsirEdition>> _fetch() async {
    final res = await Get.find<ApiProvider>().quranTafsirs();
    final list = _parse(res['tafsirs']);
    if (list.isEmpty) throw StateError('No tafsir editions');
    _storage.quranTafsirsCache = [for (final e in list) e.toJson()];
    return list;
  }

  static List<TafsirEdition> _parse(Object? data) => [
        if (data is List)
          for (final item in data)
            if (item is Map) TafsirEdition.fromJson(Map<String, dynamic>.from(item)),
      ].where((e) => e.isValid).toList();

  /// The edition for [slug] — or, when the reader hasn't chosen or their
  /// choice is gone, the default for the app's language. Null until the list
  /// has loaded.
  TafsirEdition? editionFor(String slug) {
    final list = _editions;
    if (list == null || list.isEmpty) return null;
    for (final e in list) {
      if (e.slug == slug) return e;
    }
    return defaultFor(Get.locale?.languageCode ?? 'ar');
  }

  /// The language's default edition, else its first, else Arabic's, else any.
  TafsirEdition? defaultFor(String language) {
    final list = _editions ?? const <TafsirEdition>[];
    TafsirEdition? firstOf(String code) {
      TafsirEdition? first;
      for (final e in list.where((e) => e.language == code)) {
        if (e.isDefault) return e;
        first ??= e;
      }
      return first;
    }

    return firstOf(language) ?? firstOf('ar') ?? (list.isEmpty ? null : list.first);
  }

  /// The tafsir of [surah]:[ayah] in the edition [slug] resolves to, or null
  /// when that edition has none.
  ///
  /// A tafsir that explains a group of ayahs together keeps the text on the
  /// group's first ayah and has no file (or an empty text) for the rest, so an
  /// ayah without its own text is answered from the nearest earlier one.
  /// Network failures are thrown, not treated as "no tafsir".
  Future<AyahTafsir?> ayah(String slug, int surah, int ayah) async {
    await editions();
    final edition = editionFor(slug);
    if (edition == null) return null;

    final key = '${edition.url}/$surah/$ayah';
    if (_ayahMemo.containsKey(key)) return _ayahMemo[key];

    AyahTafsir? found;
    for (var source = ayah; source >= 1 && ayah - source <= _maxLookBack; source--) {
      final data = await _getJson('${edition.url}/$surah/$source.json', missingIsNull: true);
      final text = data is Map ? (data['text'] ?? '').toString().trim() : '';
      if (text.isNotEmpty) {
        found = AyahTafsir(text: text, surah: surah, ayah: ayah, sourceAyah: source);
        break;
      }
    }

    _ayahMemo[key] = found;
    return found;
  }

  /// Decoded JSON at [url], through the tafsir cache. With [missingIsNull], a
  /// 404 answers null instead of throwing.
  Future<dynamic> _getJson(String url, {bool missingIsNull = false}) async {
    try {
      final file = await _cache.getSingleFile(url);
      return jsonDecode(await file.readAsString());
    } on HttpExceptionWithStatus catch (e) {
      if (missingIsNull && e.statusCode == 404) return null;
      rethrow;
    }
  }
}
