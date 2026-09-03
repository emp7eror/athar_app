import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Deep-links to this app's store listing, picking Play Store vs App Store
/// by platform. Used by the version tile in Settings.
class StoreLink {
  static const _androidPackageId = 'com.empire.tech.athar.athar';

  // Fill in once the app is actually live on the App Store — Apple assigns
  // this numeric id after the first submission, it can't be known ahead of
  // time. Left blank means [open] returns false on iOS rather than opening
  // a broken link.
  static const _iosAppStoreId = '';

  static Uri? _current() {
    if (Platform.isAndroid) {
      return Uri.parse('https://play.google.com/store/apps/details?id=$_androidPackageId');
    }
    if (Platform.isIOS && _iosAppStoreId.isNotEmpty) {
      return Uri.parse('https://apps.apple.com/app/id$_iosAppStoreId');
    }
    return null;
  }

  /// Opens the store listing in an external app/browser. Returns false if
  /// there's no known link for this platform (e.g. iOS before the App Store
  /// id above is filled in) or the launch itself failed.
  static Future<bool> open() async {
    final uri = _current();
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
