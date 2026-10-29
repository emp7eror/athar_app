import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/athar_typography.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/store_link.dart';
import 'my_world_globe.dart' show GlobeCamera;

/// Shares the globe as a picture: what is on screen now (the Earth, its
/// glows and the stars), with the page's words beneath it and the app's name,
/// on a 4:5 card that suits chat apps and stories alike.
abstract final class MyWorldShare {
  static const _width = 1080.0;
  static const _height = 1350.0;

  /// Captures the [RepaintBoundary] behind [globeKey] (the globe, without the
  /// panels over it) and shares the card. [globeRadius] is the globe's radius
  /// on screen, so the card frames the whole Earth, or as much as is in view
  /// when zoomed in. [glow] tints the words' soft shadow. Returns false when
  /// nothing could be shared.
  static Future<bool> share({required GlobalKey globeKey, required double globeRadius, required Color glow}) async {
    try {
      final boundary = globeKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return false;

      // The globe drawn about 900 px across, sharp on the card.
      final pixelRatio = (900 / (2 * globeRadius)).clamp(1.5, 4.0);
      final shot = await boundary.toImage(pixelRatio: pixelRatio);
      final card = await _compose(shot, boundary.size, globeRadius, pixelRatio, glow);
      shot.dispose();

      final png = await card.toByteData(format: ui.ImageByteFormat.png);
      card.dispose();
      if (png == null) return false;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/athar_my_world.png');
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: '${'my_world_share_lines'.tr}\n${StoreLink.shareUrl}'),
      );
      return true;
    } catch (e, st) {
      ErrorReporter.report(e, st);
      return false;
    }
  }

  static Future<ui.Image> _compose(ui.Image shot, Size screen, double radius, double pixelRatio, Color glow) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _width, _height));
    canvas.drawRect(const Rect.fromLTWH(0, 0, _width, _height), Paint()..color = const Color(0xFF000000));

    // The square around the globe and its halo, within what the screen shows.
    final side = math.min(2 * radius * 1.18, screen.shortestSide);
    final centre = GlobeCamera.centerIn(screen);
    final src = Rect.fromCenter(center: centre * pixelRatio, width: side * pixelRatio, height: side * pixelRatio);
    // The globe a little smaller than the card's width, leaving room below.
    const dst = Rect.fromLTWH(110, 40, 860, 860);
    canvas.drawImageRect(shot, src, dst, Paint()..filterQuality = FilterQuality.high);

    // Its foot fades into the night, so the words sit on black.
    canvas.drawRect(
      Rect.fromLTWH(0, dst.bottom - 80, _width, 90),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, dst.bottom - 80), Offset(0, dst.bottom + 10), [
          const Color(0x00000000),
          const Color(0xFF000000),
        ]),
    );

    final rtl = Get.locale?.languageCode == 'ar';
    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;

    // The words, one line each, centred, with a soft glow in the theme colour.
    final lines = 'my_world_share_lines'.tr.split('\n');
    // Clear space between the sphere (its edge ~65 px above dst.bottom) and the words.
    var y = dst.bottom + 24;
    for (final line in lines) {
      final painter = TextPainter(
        text: TextSpan(
          text: line,
          style: TextStyle(
            fontFamily: AtharFonts.arabic,
            fontSize: 58,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: const Color(0xFFF4F7F5),
            shadows: [Shadow(color: glow.withValues(alpha: 0.55), blurRadius: 28)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: direction,
      )..layout(maxWidth: _width - 120);
      painter.paint(canvas, Offset((_width - painter.width) / 2, y));
      y += painter.height + 6;
      painter.dispose();
    }

    // The app's name at the foot.
    final name = TextPainter(
      text: TextSpan(
        text: 'app_name'.tr,
        style: TextStyle(
          fontFamily: AtharFonts.arabic,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: glow.withValues(alpha: 0.9),
          letterSpacing: rtl ? 0 : 2,
        ),
      ),
      textDirection: direction,
    )..layout();
    name.paint(canvas, Offset((_width - name.width) / 2, _height - 52 - name.height));
    name.dispose();

    return recorder.endRecording().toImage(_width.toInt(), _height.toInt());
  }
}
