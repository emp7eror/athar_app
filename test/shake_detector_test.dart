import 'dart:async';

import 'package:athar/modules/dhikr/shake_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  late StreamController<UserAccelerometerEvent> sensor;
  late DateTime now;
  late ShakeDetector detector;
  late int shakes;

  final start = DateTime(2026, 9, 14, 10);

  /// Emits an acceleration of [magnitude] m/s² at [ms] after the start.
  void emit(double magnitude, int ms) {
    now = start.add(Duration(milliseconds: ms));
    sensor.add(UserAccelerometerEvent(magnitude, 0, 0, now));
  }

  setUp(() {
    // Synchronous + broadcast: events reach the detector immediately, and it
    // can stop and start listening again.
    sensor = StreamController<UserAccelerometerEvent>.broadcast(sync: true);
    now = start;
    shakes = 0;
    detector = ShakeDetector(events: () => sensor.stream, clock: () => now);
    detector.start(onShake: () => shakes++);
  });

  tearDown(() {
    detector.stop();
    sensor.close();
  });

  test('one flick counts once', () {
    emit(2, 0);
    emit(18, 20);
    emit(22, 40); // still the same movement
    emit(3, 80);
    expect(shakes, 1);
  });

  test("a flick's back-swing is not a second count", () {
    emit(18, 0);
    emit(3, 60); // settles, re-arms…
    emit(17, 150); // …but the return swing comes inside the gap
    emit(2, 220);
    expect(shakes, 1);
  });

  test('walking and a bumpy ride never count', () {
    var t = 0;
    for (final m in [2.0, 4.5, 3.1, 6.2, 5.8, 9.4, 12.0, 7.3, 3.3, 11.9, 4.0]) {
      emit(m, t += 40);
    }
    expect(shakes, 0);
  });

  test('a steady shaking rhythm counts each shake', () {
    for (var i = 0; i < 5; i++) {
      emit(19, i * 700);
      emit(2, i * 700 + 120);
    }
    expect(shakes, 5);
  });

  test('shakes closer than the minimum gap are dropped', () {
    // Every 300 ms: only 0, 600 and 1200 ms are far enough apart.
    for (var i = 0; i < 5; i++) {
      emit(19, i * 300);
      emit(2, i * 300 + 100);
    }
    expect(shakes, 3);
  });

  test('a movement held above the trigger must settle before counting again', () {
    emit(19, 0);
    emit(20, 700); // past the gap, but never dropped under the re-arm level
    emit(21, 1400);
    expect(shakes, 1);

    emit(3, 1500);
    emit(19, 1600);
    expect(shakes, 2);
  });

  test('stop ignores the sensor; start again resumes; double start is harmless', () {
    detector.stop();
    expect(detector.isListening, isFalse);
    emit(19, 0);
    expect(shakes, 0);

    detector.start(onShake: () => shakes++);
    detector.start(onShake: () => shakes++); // no second subscription
    emit(2, 700);
    emit(19, 800);
    expect(shakes, 1);
  });

  test('a device without the sensor reports unavailable and stops', () {
    detector.stop();
    var unavailable = false;
    detector.start(onShake: () => shakes++, onUnavailable: () => unavailable = true);

    sensor.addError(StateError('No user accelerometer on this device'));

    expect(unavailable, isTrue);
    expect(detector.isListening, isFalse);
  });
}
