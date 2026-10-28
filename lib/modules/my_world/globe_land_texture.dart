import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/error_reporter.dart';
import 'globe_land_raster.dart';

/// The globe's land mask, built from the bundled continents SVG.
///
/// The SVG (assets/globe/continents.svg, an amCharts map export) is a flat
/// world map in the Robinson projection. The globe's shader looks land up by
/// longitude and latitude, so the map is reprojected once: its paths are
/// filled into a raster, and every pixel of a 2:1 longitude/latitude image
/// takes its value from where that point falls on the Robinson map.
///
/// That runs in a background isolate on first open (well under a second in
/// release builds), then the result is kept as a PNG in the app's support
/// folder, keyed by the SVG's contents, so later opens only decode it. Swapping
/// the SVG for a new export of the same map rebuilds it.
///
/// Zoomed in, [detail] renders just the area in view from the same SVG at
/// the screen's resolution, so coastlines stay sharp however close it gets.
abstract final class GlobeLandTexture {
  static const svgAsset = 'assets/globe/continents.svg';

  /// Bumped when the conversion changes, so stale caches are rebuilt.
  static const _version = 2;

  /// The SVG's shapes, parsed once in the background and kept for detail.
  static Future<LandShapes>? _shapes;

  static Future<LandShapes> _loadShapes() => _shapes ??= () async {
    final svg = await rootBundle.loadString(svgAsset);
    return Isolate.run(() => GlobeLandRaster.parse(svg));
  }();

  /// [area] at [w]×[h], rendered from the SVG in the background. Null when it
  /// can't be made; the globe keeps the whole-world mask.
  static Future<GlobeLandDetail?> detail(LandArea area, int w, int h) async {
    try {
      final shapes = await _loadShapes();
      final transferable = await Isolate.run(
        () => TransferableTypedData.fromList([GlobeLandRaster.render(shapes, area, w, h)]),
      );
      final image = await _imageFromRgba(transferable.materialize().asUint8List(), w, h);
      return GlobeLandDetail(image: image, area: area, pixelsPerDegree: h / (area.dv * 180));
    } catch (e, st) {
      _shapes = null;
      ErrorReporter.report(e, st);
      return null;
    }
  }

  /// Builds or reads the mask. Null when it can't be made; the globe then
  /// draws its plain fallback.
  static Future<ui.Image?> load() async {
    try {
      final svg = await rootBundle.loadString(svgAsset);
      final cache = await _cacheFile(svg);

      if (cache != null && await cache.exists()) {
        try {
          final codec = await ui.instantiateImageCodec(await cache.readAsBytes());
          return (await codec.getNextFrame()).image;
        } catch (_) {
          // Unreadable: rebuilt below.
        }
      }

      final transferable = await Isolate.run(() => TransferableTypedData.fromList([GlobeLandRaster.build(svg)]));
      final rgba = transferable.materialize().asUint8List();
      final image = await _imageFromRgba(rgba, GlobeLandRaster.width, GlobeLandRaster.height);

      if (cache != null) {
        // Saved for next time; the globe doesn't wait for it.
        _save(image, cache);
      }
      return image;
    } catch (e, st) {
      ErrorReporter.report(e, st);
      return null;
    }
  }

  static Future<File?> _cacheFile(String svg) async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/my_world/land_v${_version}_${svg.length}_${_fnv(svg).toRadixString(16)}.png');
    } catch (_) {
      return null; // No support folder here: build every time.
    }
  }

  static Future<void> _save(ui.Image image, File file) async {
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) return;
      await file.parent.create(recursive: true);
      // Older builds (another SVG or version) are dropped.
      await for (final old in file.parent.list()) {
        if (old is File && old.path != file.path && old.path.endsWith('.png')) await old.delete();
      }
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
    } catch (e, st) {
      ErrorReporter.report(e, st);
    }
  }

  static Future<ui.Image> _imageFromRgba(Uint8List rgba, int width, int height) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }

  /// 32-bit FNV-1a of the SVG's text: a cache key, not a security check.
  static int _fnv(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h;
  }
}

/// A sharp mask of one area of the world, laid over the whole-world one.
class GlobeLandDetail {
  const GlobeLandDetail({required this.image, required this.area, required this.pixelsPerDegree});

  final ui.Image image;
  final LandArea area;

  /// Its resolution along a meridian.
  final double pixelsPerDegree;
}
