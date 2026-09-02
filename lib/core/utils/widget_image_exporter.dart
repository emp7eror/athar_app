import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Rasterizes a widget subtree — wrapped by the caller in a [RepaintBoundary]
/// with [boundaryKey] attached — into a PNG file, without pulling in a
/// screenshot package. Used to turn the achievement card into a shareable
/// image.
class WidgetImageExporter {
  /// Captures the [RepaintBoundary] identified by [boundaryKey] and writes it
  /// to a temp PNG file, returning the file path. Returns null if the
  /// boundary isn't mounted (e.g. called before the first frame).
  static Future<String?> captureToFile(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
    String filename = 'athar_achievement.png',
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file.path;
  }
}
