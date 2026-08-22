import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../utils/error_reporter.dart';

/// In-app sound effects (distinct from OS notification sounds).
///
/// Currently just the completion chime played when a prayer is marked done.
/// A single reused player prevents overlapping playback, and every call is
/// guarded so a missing/604 asset never bubbles an exception into the UI.
class SoundService extends GetxService {
  final _player = AudioPlayer(playerId: 'athar_sfx');

  Future<SoundService> init() async {
    // Respect the device's media/ringer volume rather than forcing full blast.
    await _player.setReleaseMode(ReleaseMode.stop);
    return this;
  }

  /// Play the prayer-completion chime. No-op (logged) if the asset is missing.
  Future<void> playPrayerDone() => _play('audio/done.mp3');

  Future<void> _play(String assetPath) async {
    try {
      await _player.stop(); // avoid overlap if tapped rapidly
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      debugPrint('SoundService: could not play $assetPath — $e');
    }
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
