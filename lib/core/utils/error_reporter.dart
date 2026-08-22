import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/providers/api_provider.dart';

class ErrorReporter {
  ErrorReporter._();

  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      return true;
    };
  }

  static void report(Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('🔴 $error\n$stack');
      return;
    }

    try {
      final api = Get.find<ApiProvider>();
      api.logError(
        error:      error.toString(),
        stack:       stack?.toString(),
        platform:   Platform.operatingSystem,
        appVersion: '1.0.0',
        device:     Platform.localHostname,
        route:      Get.currentRoute,
      );
    } catch (e) {ErrorReporter.report(e, StackTrace.current);
    }
  }
}