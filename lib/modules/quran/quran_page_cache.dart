import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Permanent disk store for Mushaf pages.
///
/// Two things make it permanent rather than merely long-lived:
///
/// 1. [DefaultCacheManager] keeps only 200 files for 30 days — wrong for a
///    604-page Mushaf, where a reader passing page 200 would silently start
///    losing the earliest ones. This store holds the whole Mushaf and never
///    ages it out.
/// 2. [fetch] reads a page straight from disk and only ever goes to the network
///    when the file isn't there. `getSingleFile` would re-validate against the
///    server whenever its headers say the copy is stale — and a CDN sending
///    `no-cache` would make that *every single open*. Mushaf pages don't
///    change, so once a page is on the device it is never fetched again.
class QuranPageCache {
  QuranPageCache._();

  static const key = 'athar_quran_pages';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      // Effectively never: the pages are immutable, so there is nothing to
      // refresh and no reason to spend the reader's data twice on one page.
      stalePeriod: const Duration(days: 36500),
      // The whole Mushaf, with room to spare.
      maxNrOfCacheObjects: 1000,
    ),
  );

  /// The page's file, downloading it only if this device has never held it.
  ///
  /// Returns null when the page isn't cached and can't be fetched — offline on
  /// a page that was never opened before.
  /// Requests already running, so two callers asking for the same page share
  /// one download instead of racing each other to fetch it twice.
  static final Map<String, Future<File?>> _inFlight = <String, Future<File?>>{};

  static Future<File?> fetch(String url) {
    final running = _inFlight[url];
    if (running != null) return running;

    final request = _fetch(url);
    _inFlight[url] = request;
    return request.whenComplete(() => _inFlight.remove(url));
  }

  static Future<File?> _fetch(String url) async {
    final name = _name(url);

    final cached = await instance.getFileFromCache(url);
    if (cached != null && await cached.file.exists()) {
      final bytes = await cached.file.length();
      _log('cache hit   $name  ${_kb(bytes)}');
      return cached.file;
    }

    final started = DateTime.now();
    _log('downloading $name  $url');

    try {
      final downloaded = await instance.downloadFile(url);
      final bytes = await downloaded.file.length();
      final ms = DateTime.now().difference(started).inMilliseconds;
      _log('downloaded  $name  ${_kb(bytes)}  in ${ms}ms');
      return downloaded.file;
    } catch (e) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      _log('FAILED      $name  after ${ms}ms  -> $e');
      return null;
    }
  }

  /// Reports how much of the Mushaf this device is already holding. Debug only
  /// — it stats every one of the 604 pages, which is far too much work to do on
  /// a reader's device for a line they will never see.
  static Future<void> logHeld(int totalPages, String Function(int) urlFor) async {
    if (!kDebugMode) return;

    var held = 0;
    var bytes = 0;

    for (var page = 1; page <= totalPages; page++) {
      final url = urlFor(page);
      if (url.isEmpty) continue;
      final info = await instance.getFileFromCache(url);
      if (info == null || !await info.file.exists()) continue;
      held++;
      bytes += await info.file.length();
    }

    _log('stored $held/$totalPages pages, ${_kb(bytes)} on disk');
  }

  static String _name(String url) => url.split('/').last;

  static String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(0)}KB';

  static void _log(String message) => debugPrint('[quran/page] $message');

  /// Whether this page is already on the device — used to skip needless work.
  static Future<bool> has(String url) async {
    final cached = await instance.getFileFromCache(url);
    return cached != null && await cached.file.exists();
  }
}
