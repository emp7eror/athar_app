import 'dart:math' as math;
import 'dart:typed_data';

/// The continents SVG, parsed: its viewBox and every closed shape as a flat
/// [x0, y0, x1, y1, …] list in the SVG's own units. Plain data, so it can be
/// sent to a background isolate.
class LandShapes {
  const LandShapes(this.viewBox, this.polygons);

  /// x, y, width, height.
  final List<double> viewBox;
  final List<Float64List> polygons;
}

/// A rectangle of the world in the shader's uv: u is longitude (0 at -180°,
/// 1 at 180°; may run past either end and wraps), v is latitude (0 at the
/// north pole, 1 at the south).
class LandArea {
  const LandArea(this.u0, this.v0, this.du, this.dv);

  static const world = LandArea(0, 0, 1, 1);

  final double u0;
  final double v0;
  final double du;
  final double dv;

  /// Whether this area holds [other] entirely.
  bool contains(LandArea other) {
    if (other.v0 < v0 || other.v0 + other.dv > v0 + dv) return false;
    if (du >= 1) return true;
    final start = (other.u0 - u0) % 1.0;
    return start + other.du <= du;
  }
}

/// Turns the continents SVG (a Robinson world map) into longitude/latitude
/// land masks for the globe's shader: the whole world once, and the area in
/// view at screen resolution when zoomed in. The SVG is vector, so any area
/// can be drawn as sharp as the screen needs.
///
/// Pure Dart, no Flutter: it runs in background isolates (see
/// GlobeLandTexture), and can be run on its own.
abstract final class GlobeLandRaster {
  /// The whole-world mask's size.
  static const width = 2880;
  static const height = 1440;

  /// Largest side of a detail mask, and the most raster pixels behind one.
  static const maxDetailSide = 2048;
  static const _maxRasterPixels = 4096 * 4096;

  /// Robinson table, every 5° of latitude: parallel length and distance from
  /// the equator, as published by Robinson (1974).
  static const _plen = [
    1.0, 0.9986, 0.9954, 0.99, 0.9822, 0.973, 0.96, 0.9427, 0.9216, 0.8962, //
    0.8679, 0.835, 0.7986, 0.7597, 0.7186, 0.6732, 0.6213, 0.5722, 0.5322,
  ];
  static const _pdfe = [
    0.0, 0.062, 0.124, 0.186, 0.248, 0.31, 0.372, 0.434, 0.4958, 0.5571, //
    0.6176, 0.6769, 0.7346, 0.7903, 0.8435, 0.8936, 0.9394, 0.9761, 1.0,
  ];

  /// Where the map sits in its viewBox, as fractions of it: fitted to the
  /// amCharts export (pole line, date-line edges and coastline points, all
  /// within 0.3 px). A re-export of the same map at another size scales with
  /// its viewBox; a different framing or projection would need a new fit.
  static const _centerX = 0.498357; // longitude 0, of the width
  static const _centerY = 0.491487; // the equator, of the height
  static const _scale = 0.189516; // Robinson's unit, of the width

  /// The whole-world mask as RGBA bytes, [width]×[height], grey = land.
  static Uint8List build(String svg) => render(parse(svg), LandArea.world, width, height);

  /// [area] of the world as a [w]×[h] RGBA mask, grey = land coverage.
  static Uint8List render(LandShapes shapes, LandArea area, int w, int h) {
    final vb = shapes.viewBox;
    final cx = vb[0] + vb[2] * _centerX;
    final cy = vb[1] + vb[3] * _centerY;
    final s = vb[2] * _scale;
    final lon0 = area.u0 * 360 - 180;
    final lonSpan = area.du * 360;
    final lat0 = 90 - area.v0 * 180;
    final latSpan = area.dv * 180;

    double wrap(double lon) => (lon + 180) % 360 - 180;

    // The area's footprint on the map, from points along its edges (the
    // projection is monotonic along parallels and meridians), so only that
    // part of the SVG is filled.
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    const steps = 48;
    for (var a = 0; a <= steps; a++) {
      for (var b = 0; b <= steps; b++) {
        if (a != 0 && a != steps && b != 0 && b != steps) continue;
        final p = _project(wrap(lon0 + lonSpan * a / steps), lat0 - latSpan * b / steps, cx, cy, s);
        minX = math.min(minX, p.$1);
        maxX = math.max(maxX, p.$1);
        minY = math.min(minY, p.$2);
        maxY = math.max(maxY, p.$2);
      }
    }
    // An area across the date line touches both edges of the map.
    final crossesDateLine = lon0 < -180 || lon0 + lonSpan > 180 || area.du >= 1;
    if (crossesDateLine) {
      minX = vb[0];
      maxX = vb[0] + vb[2];
    }
    final pad = vb[2] * 0.002;
    minX = math.max(vb[0], minX - pad);
    maxX = math.min(vb[0] + vb[2], maxX + pad);
    minY = math.max(vb[1], minY - pad);
    maxY = math.min(vb[1] + vb[3], maxY + pad);

    // Raster density: twice the output's over the footprint, within a budget.
    final bw = math.max(maxX - minX, 1e-6), bh = math.max(maxY - minY, 1e-6);
    final budget = math.sqrt(_maxRasterPixels / (bw * bh));
    final k = math.min(2.0 * math.max(w / bw, h / bh), budget);
    final rw = math.max(1, (bw * k).ceil());
    final rh = math.max(1, (bh * k).ceil());
    final raster = _rasterize(shapes.polygons, minX, minY, k, rw, rh);

    // One sample per pixel for a detail mask (its raster is dense enough to
    // smooth the edge); 2×2 for the whole world.
    final subs = area.du >= 1 && area.dv >= 1 ? const [0.25, 0.75] : const [0.5];
    final n = subs.length;
    final lonRad = Float64List(w * n);
    for (var i = 0; i < w; i++) {
      for (var q = 0; q < n; q++) {
        lonRad[i * n + q] = wrap(lon0 + (i + subs[q]) / w * lonSpan) * math.pi / 180;
      }
    }

    final out = Uint8List(w * h * 4);
    final ry = Float64List(n);
    final kx = Float64List(n);
    final base = (cx - minX) * k;
    for (var j = 0; j < h; j++) {
      // Each sub-row is one latitude: one y on the map, one parallel length.
      for (var q = 0; q < n; q++) {
        final lat = (lat0 - (j + subs[q]) / h * latSpan).clamp(-90.0, 90.0);
        final r = _robinson(lat);
        ry[q] = (cy - s * 1.3523 * r.$2 - minY) * k;
        kx[q] = s * 0.8487 * r.$1 * k;
      }
      for (var i = 0; i < w; i++) {
        var sum = 0.0;
        for (var qy = 0; qy < n; qy++) {
          for (var qx = 0; qx < n; qx++) {
            sum += _sample(raster, rw, rh, base + kx[qy] * lonRad[i * n + qx], ry[qy]);
          }
        }
        final v = (sum / (n * n)).round();
        final o = (j * w + i) * 4;
        out[o] = v;
        out[o + 1] = v;
        out[o + 2] = v;
        out[o + 3] = 255;
      }
    }
    return out;
  }

  /// Robinson's parallel length and (signed) distance from the equator at [lat].
  static (double, double) _robinson(double lat) {
    final a = lat.abs() / 5;
    final i0 = math.min(a.floor(), 17);
    final f = a - i0;
    final plen = _plen[i0] + (_plen[i0 + 1] - _plen[i0]) * f;
    final pdfe = _pdfe[i0] + (_pdfe[i0 + 1] - _pdfe[i0]) * f;
    return (plen, pdfe * lat.sign);
  }

  /// [lon]/[lat] (degrees) on the map, in the SVG's units.
  static (double, double) _project(double lon, double lat, double cx, double cy, double s) {
    final r = _robinson(lat);
    return (cx + s * 0.8487 * r.$1 * lon * math.pi / 180, cy - s * 1.3523 * r.$2);
  }

  /// Bilinear sample of [r] at raster position ([x], [y]) (pixel centres at +0.5).
  static double _sample(Uint8List r, int w, int h, double x, double y) {
    if (w < 2 || h < 2) return 0;
    x = (x - 0.5).clamp(0.0, w - 1.001);
    y = (y - 0.5).clamp(0.0, h - 1.001);
    final x0 = x.floor();
    final y0 = y.floor();
    final fx = x - x0;
    final fy = y - y0;
    final i = y0 * w + x0;
    return r[i] * (1 - fx) * (1 - fy) + r[i + 1] * fx * (1 - fy) + r[i + w] * (1 - fx) * fy + r[i + w + 1] * fx * fy;
  }

  /// The SVG's viewBox and shapes.
  static LandShapes parse(String svg) => LandShapes(_viewBox(svg), _polygons(svg));

  static List<double> _viewBox(String svg) {
    final m = RegExp(r'viewBox="([^"]+)"').firstMatch(svg);
    if (m != null) {
      final v = m.group(1)!.trim().split(RegExp(r'[\s,]+')).map(double.parse).toList();
      if (v.length == 4 && v[2] > 0 && v[3] > 0) return v;
    }
    double attr(String name) => double.parse(RegExp('$name="([\\d.]+)"').firstMatch(svg)!.group(1)!);
    return [0, 0, attr('width'), attr('height')];
  }

  /// Every closed shape in the SVG's paths, as flat [x0, y0, x1, y1, …] lists.
  /// The map uses only straight segments (M, L, H, V, Z, absolute or
  /// relative); any curve is taken as a line to its end point.
  static List<Float64List> _polygons(String svg) {
    final polygons = <Float64List>[];
    for (final m in RegExp(r'<path\b[^>]*?\sd="([^"]*)"', dotAll: true).allMatches(svg)) {
      final tokens = RegExp(
        r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
      ).allMatches(m.group(1)!).map((t) => t.group(0)!).toList();
      var current = <double>[];
      var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
      var cmd = 'M';
      var i = 0;

      void close() {
        if (current.length >= 6) polygons.add(Float64List.fromList(current));
        current = <double>[];
      }

      double next() => double.parse(tokens[i++]);
      bool isCmd(String t) => t.length == 1 && (t.codeUnitAt(0) | 0x20) >= 0x61 && (t.codeUnitAt(0) | 0x20) <= 0x7a;

      while (i < tokens.length) {
        if (isCmd(tokens[i])) cmd = tokens[i++];
        final rel = cmd == cmd.toLowerCase();
        switch (cmd.toUpperCase()) {
          case 'Z':
            close();
            x = startX;
            y = startY;
            continue;
          case 'M':
            close();
            x = (rel ? x : 0) + next();
            y = (rel ? y : 0) + next();
            startX = x;
            startY = y;
            current.addAll([x, y]);
            // Further pairs after a move are lines.
            cmd = rel ? 'l' : 'L';
          case 'L':
            x = (rel ? x : 0) + next();
            y = (rel ? y : 0) + next();
            current.addAll([x, y]);
          case 'H':
            x = (rel ? x : 0) + next();
            current.addAll([x, y]);
          case 'V':
            y = (rel ? y : 0) + next();
            current.addAll([x, y]);
          default:
            // C, S, Q, T (pairs) or A (7 numbers): skip to the end point.
            final n = switch (cmd.toUpperCase()) {
              'C' => 6,
              'S' || 'Q' => 4,
              'T' => 2,
              'A' => 7,
              _ => 0,
            };
            if (n == 0 || i + n > tokens.length) {
              i = tokens.length;
              break;
            }
            final values = [for (var k = 0; k < n; k++) next()];
            x = (rel ? x : 0) + values[n - 2];
            y = (rel ? y : 0) + values[n - 1];
            current.addAll([x, y]);
        }
      }
      close();
    }
    return polygons;
  }

  /// Fills [polygons] (non-zero winding) into a [w]×[h] raster of 0/255: the
  /// SVG's units from ([ox], [oy]) at [k] raster pixels each, one sample per
  /// pixel centre, scanline by scanline. Edges outside the raster are skipped.
  static Uint8List _rasterize(List<Float64List> polygons, double ox, double oy, double k, int w, int h) {
    // Edge table, scaled to the raster: top, bottom, x at top, dx/dy, winding.
    final top = <double>[], bottom = <double>[], xTop = <double>[], slope = <double>[];
    final dir = <int>[];
    for (final p in polygons) {
      final n = p.length ~/ 2;
      for (var e = 0; e < n; e++) {
        final x0 = (p[e * 2] - ox) * k, y0 = (p[e * 2 + 1] - oy) * k;
        final e1 = (e + 1) % n;
        final x1 = (p[e1 * 2] - ox) * k, y1 = (p[e1 * 2 + 1] - oy) * k;
        if (y0 == y1) continue;
        final down = y1 > y0;
        final t = down ? y0 : y1, b = down ? y1 : y0;
        if (b <= 0 || t >= h) continue;
        top.add(t);
        bottom.add(b);
        xTop.add(down ? x0 : x1);
        slope.add((x1 - x0) / (y1 - y0));
        dir.add(down ? 1 : -1);
      }
    }
    final order = List<int>.generate(top.length, (i) => i)..sort((a, b) => top[a].compareTo(top[b]));

    final raster = Uint8List(w * h);
    final active = <int>[];
    var nextEdge = 0;
    final xs = <double>[];
    final ws = <int>[];
    final idx = <int>[];

    for (var row = 0; row < h; row++) {
      final yc = row + 0.5;
      while (nextEdge < order.length && top[order[nextEdge]] <= yc) {
        active.add(order[nextEdge++]);
      }
      active.removeWhere((e) => bottom[e] <= yc);
      if (active.isEmpty) continue;

      xs.clear();
      ws.clear();
      for (final e in active) {
        xs.add(xTop[e] + (yc - top[e]) * slope[e]);
        ws.add(dir[e]);
      }
      idx
        ..clear()
        ..addAll(List<int>.generate(xs.length, (i) => i))
        ..sort((a, b) => xs[a].compareTo(xs[b]));

      var winding = 0;
      final rowStart = row * w;
      for (var q = 0; q < idx.length; q++) {
        final before = winding;
        winding += ws[idx[q]];
        if (before == 0 && winding != 0 && q + 1 < idx.length) {
          // Span opens here; find where the winding returns to zero.
          var wsum = winding;
          var end = q + 1;
          while (end < idx.length) {
            wsum += ws[idx[end]];
            if (wsum == 0) break;
            end++;
          }
          if (end >= idx.length) break;
          final from = math.max(0, (xs[idx[q]] - 0.5).ceil());
          final to = math.min(w, (xs[idx[end]] - 0.5).ceil());
          for (var c = from; c < to; c++) {
            raster[rowStart + c] = 255;
          }
          winding = 0;
          q = end;
        }
      }
    }
    return raster;
  }
}
