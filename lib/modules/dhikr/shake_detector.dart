import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Turns the phone's motion sensor into discrete "shakes" for the dhikr counter.
///
/// Reads *user* acceleration (gravity already removed), so a phone held still
/// at any angle reads as zero. A shake counts when the acceleration spikes past
/// [trigger]; the movement must then settle under [rearm] before another shake
/// can count, and counts are at least [minGap] apart. One flick of the wrist is
/// one count — its out-and-back swing isn't two — and walking or a bumpy ride
/// stays well below the trigger.
class ShakeDetector {
  ShakeDetector({
    this.trigger = 5,
    this.rearm = 5,
    this.minGap = const Duration(milliseconds: 600),
    Stream<UserAccelerometerEvent> Function()? events,
    DateTime Function()? clock,
  })  : _events = events ??
            (() => userAccelerometerEventStream(
                  samplingPeriod: SensorInterval.gameInterval,
                )),
        _clock = clock ?? DateTime.now;

  /// m/s² needed to count — a deliberate flick (~1.5 g), far above walking
  /// (~2–5 m/s²).
  final double trigger;

  /// m/s² the movement must settle under before the next shake can count.
  final double rearm;

  /// Kept above DhikrController's rapid-tap threshold (500 ms), so a steady
  /// shaking rhythm is never mistaken for a frantic run and paused.
  final Duration minGap;

  final Stream<UserAccelerometerEvent> Function() _events;
  final DateTime Function() _clock;

  StreamSubscription<UserAccelerometerEvent>? _sub;
  bool _armed = true;
  DateTime? _lastShake;

  bool get isListening => _sub != null;

  /// Starts listening. [onUnavailable] fires (and listening stops) if the
  /// device has no usable motion sensor. Calling it again while listening does
  /// nothing.
  void start({
    required void Function() onShake,
    void Function()? onUnavailable,
  }) {
    if (_sub != null) return;
    _armed = true;

    _sub = _events().listen(
      (e) {
        final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

        if (!_armed) {
          if (magnitude < rearm) _armed = true;
          return;
        }
        if (magnitude < trigger) return;

        // Past the trigger: this movement is used up either way.
        _armed = false;

        final now = _clock();
        final last = _lastShake;
        if (last != null && now.difference(last) < minGap) return;

        _lastShake = now;
        onShake();
      },
      onError: (Object _) {
        stop();
        onUnavailable?.call();
      },
      cancelOnError: true,
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
