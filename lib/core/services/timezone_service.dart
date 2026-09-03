import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';

import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../utils/error_reporter.dart';

/// Owns the device's IANA timezone and keeps the server's pinned copy in sync.
///
/// The server treats its own stored timezone as the source of truth for "what
/// time is it for this user" — that's what makes a shifted device clock
/// detectable. This service's job is only to (a) cache the identifier locally
/// so we stop hitting the platform channel on every request, and (b) report a
/// genuine change (travel) so the pinned copy doesn't go stale.
class TimezoneService extends GetxService {
  final _store = Get.find<StorageProvider>();

  /// Reactive so the Settings screen can display the current value.
  final current = ''.obs;

  Future<TimezoneService> init() async {
    current.value = _store.timezone ?? await _detect();
    return this;
  }

  /// Cached identifier — falls back to a fresh platform lookup on a cold cache.
  Future<String> resolve() async {
    final cached = _store.timezone;
    if (cached != null && cached.isNotEmpty) return cached;

    final detected = await _detect();
    current.value = detected;
    return detected;
  }

  /// Detects the device timezone and, when it differs from the pinned value,
  /// reports it. The server enforces its own once-per-day cap and answers 429
  /// if the change is too soon — in which case the local cache deliberately
  /// stays on the previously accepted value.
  Future<void> syncIfChanged() async {
    try {
      print('ddd');
      final detected = await _detect();
      print(detected);

      if (detected.isEmpty || detected == _store.timezone) return;

      await Get.find<ApiProvider>().updateTimezone(detected);

      _store.timezone = detected;
      _store.timezoneReportedAt = DateTime.now();
      current.value = detected;
    } catch (e) {
      // Non-critical: a failed sync just means the server keeps the previous
      // pinned zone, which is the safe outcome.
      ErrorReporter.report(e, StackTrace.current);
    }
  }

  Future<String> _detect() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      return _store.timezone ?? '';
    }
  }
}
