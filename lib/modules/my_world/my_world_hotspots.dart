import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'my_world_globe.dart' show GlobeCamera;
import 'my_world_models.dart';

/// How activity glows on the globe.
///
/// The glow itself is drawn by the globe's shader (shaders/globe.frag), on
/// the sphere: each place is a soft gaussian of light measured by angle on
/// the Earth's surface, so it follows the curvature, turns with the globe and
/// is simply absent on the far side. Spots add up and saturate softly, so
/// neighbours merge into one lit region with no edge. Each breathes — a
/// little wider and brighter, then back — on its own slow cycle.
///
/// Size and strength follow the server's log-scaled intensity (0..1), with a
/// ceiling, so one record still glows and the busiest place never floods the
/// map. At world scale the glows are broad; zooming in narrows them until
/// each place stands on its own.
abstract final class HotspotStyle {
  /// Most places the shader lights at once. With more, the ones facing the
  /// viewer and the busiest win.
  static const maxSpots = 32;

  /// One breath, seconds (the shader's 4.2 matches).
  static const breathPeriod = 4.2;

  /// A spot's spread at world scale, radians: wider with more records,
  /// between 4° and 11°.
  static double sigma(double intensity) => (4.0 + 7.0 * math.sqrt(intensity)) * math.pi / 180;

  /// A spot's strength, 0..1; places known only by country glow fainter.
  static double amplitude(WorldCluster c) => (0.35 + 0.45 * c.intensity) * (c.approximate ? 0.7 : 1.0);

  /// How much the glows narrow at [zoom]: 1 at world scale, down to 0.05
  /// (a few kilometres) fully zoomed in, so each place stands on its own.
  static double spread(double zoom) => math.pow(1.2 / zoom.clamp(1.2, 100.0), 1.3).toDouble().clamp(0.05, 1.0);

  /// [brand] at full brightness, keeping its hue: theme brand colours can be
  /// nearly black, which wouldn't light anything.
  static Color lit(Color brand) {
    final peak = math.max(brand.r, math.max(brand.g, brand.b));
    if (peak < 0.01) return const Color(0xFFFFFFFF);
    return Color.from(alpha: 1, red: brand.r / peak, green: brand.g / peak, blue: brand.b / peak);
  }
}

/// The clusters as the globe needs them, worked out once when they change:
/// each place as a unit vector, its spread, strength and breathing phase.
/// Each frame only rotates the vectors (for taps and the count card) and
/// picks which places the shader lights.
class HotspotField {
  HotspotField(this.clusters)
    : _x = List<double>.filled(clusters.length, 0),
      _y = List<double>.filled(clusters.length, 0),
      _z = List<double>.filled(clusters.length, 0),
      _screen = List<Offset>.filled(clusters.length, Offset.zero),
      _facing = List<double>.filled(clusters.length, 0),
      _depth = List<double>.filled(clusters.length, 0) {
    for (var k = 0; k < clusters.length; k++) {
      final c = clusters[k];
      final phi = c.lat * math.pi / 180;
      final lambda = c.lng * math.pi / 180;
      _x[k] = math.cos(phi) * math.sin(lambda);
      _y[k] = math.sin(phi);
      _z[k] = math.cos(phi) * math.cos(lambda);
    }
    // Busiest first, so a tie for the shader's places goes to them.
    _byIntensity = List<int>.generate(clusters.length, (k) => k)
      ..sort((a, b) => clusters[b].intensity.compareTo(clusters[a].intensity));
  }

  final List<WorldCluster> clusters;
  final List<double> _x, _y, _z;
  late final List<int> _byIntensity;

  // At the last [project]: where each sits on screen, how much it faces the
  // viewer (0 at the edge or behind), and its raw depth.
  final List<Offset> _screen;
  final List<double> _facing, _depth;

  int get length => clusters.length;
  Offset screen(int k) => _screen[k];
  double facing(int k) => _facing[k];

  int indexOf(String? id) => id == null ? -1 : clusters.indexWhere((c) => c.id == id);

  /// Places every hotspot for [camera] in a canvas of [size].
  void project(GlobeCamera camera, Size size) {
    final cy = math.cos(camera.yaw), sy = math.sin(camera.yaw);
    final cp = math.cos(camera.pitch), sp = math.sin(camera.pitch);
    final r = camera.radiusIn(size);
    final centre = GlobeCamera.centerIn(size);
    final cx0 = centre.dx, cy0 = centre.dy;
    for (var k = 0; k < length; k++) {
      final x1 = _x[k] * cy + _z[k] * sy;
      final z1 = -_x[k] * sy + _z[k] * cy;
      final y2 = _y[k] * cp - z1 * sp;
      final z2 = _y[k] * sp + z1 * cp;
      _screen[k] = Offset(cx0 + x1 * r, cy0 - y2 * r);
      _depth[k] = z2;
      _facing[k] = ((z2 - 0.02) / 0.18).clamp(0.0, 1.0);
    }
  }

  /// Roughly how far [k]'s glow reaches on screen at [camera]'s zoom.
  double glowRadius(int k, GlobeCamera camera, Size size) =>
      HotspotStyle.sigma(clusters[k].intensity) * HotspotStyle.spread(camera.zoom) * camera.radiusIn(size);

  /// The hotspot under [position], or -1. Uses the last [project].
  int hit(Offset position, GlobeCamera camera, Size size) {
    var best = -1;
    var bestDistance = double.infinity;
    for (var k = 0; k < length; k++) {
      if (_facing[k] <= 0.05) continue;
      // The bright middle of the glow, and at least a finger's width.
      final reach = glowRadius(k, camera, size).clamp(24.0, 90.0);
      final d = (_screen[k] - position).distance;
      if (d <= reach && d < bestDistance) {
        best = k;
        bestDistance = d;
      }
    }
    return best;
  }

  /// The places the shader lights this frame (all of them, up to
  /// [HotspotStyle.maxSpots]; beyond that the ones facing the viewer, busiest
  /// first), always including [selected]. Uses the last [project].
  List<int> lit(int selected) {
    if (length <= HotspotStyle.maxSpots) return List<int>.generate(length, (k) => k);
    final picked = <int>[if (selected >= 0) selected];
    // Facing first (a glow can reach round the edge a little), then the rest.
    for (final front in [true, false]) {
      for (final k in _byIntensity) {
        if (picked.length >= HotspotStyle.maxSpots) return picked;
        if ((_depth[k] > -0.15) == front && k != selected) picked.add(k);
      }
    }
    return picked;
  }

  /// Writes the glow uniforms into [shader] from float [offset]: count,
  /// selected slot, spread, two theme colours, then each lit place as
  /// (x, y, z, sigma) and (amplitude, phase, 0, 0). Unused slots are zeroed
  /// so nothing stale lights.
  void writeUniforms(
    ui.FragmentShader shader,
    int offset,
    GlobeCamera camera, {
    required int selected,
    required Color glow,
    required Color highlight,
  }) {
    final spots = lit(selected);
    var o = offset;
    shader
      ..setFloat(o++, spots.length.toDouble())
      ..setFloat(o++, selected < 0 ? -1 : spots.indexOf(selected).toDouble())
      ..setFloat(o++, HotspotStyle.spread(camera.zoom))
      ..setFloat(o++, 0)
      ..setFloat(o++, glow.r)
      ..setFloat(o++, glow.g)
      ..setFloat(o++, glow.b)
      ..setFloat(o++, highlight.r)
      ..setFloat(o++, highlight.g)
      ..setFloat(o++, highlight.b);
    final b = o + HotspotStyle.maxSpots * 4;
    for (var slot = 0; slot < HotspotStyle.maxSpots; slot++) {
      final a = o + slot * 4, c = b + slot * 4;
      if (slot < spots.length) {
        final k = spots[slot];
        final cluster = clusters[k];
        shader
          ..setFloat(a, _x[k])
          ..setFloat(a + 1, _y[k])
          ..setFloat(a + 2, _z[k])
          ..setFloat(a + 3, HotspotStyle.sigma(cluster.intensity))
          ..setFloat(c, HotspotStyle.amplitude(cluster))
          // Out of step with each other, so the globe doesn't throb as one.
          ..setFloat(c + 1, (cluster.id.hashCode & 0xffff) / 0xffff * 2 * math.pi)
          ..setFloat(c + 2, 0)
          ..setFloat(c + 3, 0);
      } else {
        for (var q = 0; q < 4; q++) {
          shader
            ..setFloat(a + q, 0)
            ..setFloat(c + q, 0);
        }
      }
    }
  }

  /// Dashed rings round places known only by country: "somewhere around
  /// here". Few, so drawn one by one over the globe.
  void paintApproximate(Canvas canvas, GlobeCamera camera, Size size, Color color) {
    for (var k = 0; k < length; k++) {
      if (!clusters[k].approximate || _facing[k] <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = color.withValues(alpha: 0.5 * _facing[k]);
      const dashes = 16;
      const sweep = math.pi / dashes;
      final ring = Rect.fromCircle(center: _screen[k], radius: glowRadius(k, camera, size).clamp(14.0, 70.0));
      for (var d = 0; d < dashes; d++) {
        canvas.drawArc(ring, d * 2 * sweep, sweep, false, paint);
      }
    }
  }

  /// Soft discs for when the shader can't run (or hasn't loaded yet), so the
  /// places still show.
  void paintFallback(Canvas canvas, GlobeCamera camera, Size size, Color glow) {
    for (var k = 0; k < length; k++) {
      final f = _facing[k];
      if (f <= 0) continue;
      final r = glowRadius(k, camera, size).clamp(10.0, 120.0) * 1.6;
      final a = HotspotStyle.amplitude(clusters[k]) * f * 0.55;
      canvas.drawCircle(
        _screen[k],
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(_screen[k], r, [glow.withValues(alpha: a), glow.withValues(alpha: 0)]),
      );
    }
  }
}
