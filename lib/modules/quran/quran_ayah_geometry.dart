import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// One ayah: its surah and number.
@immutable
class AyahRef {
  const AyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  /// Mushaf order: a larger value comes later.
  int get order => surah * 1000 + ayah;

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}

/// An inclusive run of ayahs within one surah.
@immutable
class AyahRange {
  const AyahRange(this.surah, this.start, this.end);

  final int surah;
  final int start;
  final int end;

  bool contains(AyahRef ref) =>
      ref.surah == surah && ref.ayah >= start && ref.ayah <= end;

  @override
  bool operator ==(Object other) =>
      other is AyahRange &&
      other.surah == surah &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(surah, start, end);
}

class AyahShape {
  const AyahShape(this.ref, this.path);

  final AyahRef ref;

  /// In the page's own SVG user space.
  final Path path;
}

/// Where each ayah sits on a Mushaf page, read from the page's own SVG.
///
/// The page SVGs (quranpedia/quran-svg; the polygon layer is CC0) carry a
/// transparent `<path class="ayahPolygon" surah=… ayah=… d=…>` for every ayah,
/// in the same user space as the script. The geometry therefore arrives with
/// the page the reader already downloads — no second file per page.
class PageGeometry {
  const PageGeometry(this.viewBox, this.ayahs);

  static const empty = PageGeometry(Rect.fromLTWH(0, 0, 345, 550), []);

  final Rect viewBox;
  final List<AyahShape> ayahs;

  /// Whether [ref] is (at least partly) on this page.
  bool contains(AyahRef ref) => ayahs.any((s) => s.ref == ref);

  /// Parses off the UI thread: a page is around half a megabyte of markup.
  static Future<PageGeometry> parse(Uint8List svg) async {
    final raw = await compute(_extract, svg);

    final box = raw.viewBox;
    final viewBox = box.length == 4 && box[2] > 0 && box[3] > 0
        ? Rect.fromLTWH(box[0], box[1], box[2], box[3])
        : empty.viewBox;

    final ayahs = <AyahShape>[];
    for (final shape in raw.shapes) {
      final path = Path();
      for (final points in shape.polygons) {
        path.moveTo(points[0], points[1]);
        for (var i = 2; i + 1 < points.length; i += 2) {
          path.lineTo(points[i], points[i + 1]);
        }
        path.close();
      }
      ayahs.add(AyahShape(AyahRef(shape.surah, shape.ayah), path));
    }

    return PageGeometry(viewBox, ayahs);
  }

  /// The scale and offset [SvgPicture] uses to draw the page with
  /// `BoxFit.contain`, centred, in a box of [size].
  ({double scale, Offset offset}) fit(Size size) {
    final scale = (size.width / viewBox.width) < (size.height / viewBox.height)
        ? size.width / viewBox.width
        : size.height / viewBox.height;
    return (
      scale: scale,
      offset: Offset(
        (size.width - viewBox.width * scale) / 2,
        (size.height - viewBox.height * scale) / 2,
      ),
    );
  }

  /// The ayah under [local], a point in a box of [size] drawn with [fit].
  AyahRef? ayahAt(Offset local, Size size) {
    final f = fit(size);
    final point = Offset(
      (local.dx - f.offset.dx) / f.scale + viewBox.left,
      (local.dy - f.offset.dy) / f.scale + viewBox.top,
    );
    for (final shape in ayahs) {
      if (shape.path.contains(point)) return shape.ref;
    }
    return null;
  }
}

typedef _RawShape = ({int surah, int ayah, List<List<double>> polygons});

final _tag = RegExp(r'<path\b[^>]*\bclass="ayahPolygon"[^>]*>');
final _attribute = RegExp(r'([\w:-]+)="([^"]*)"');
final _viewBox = RegExp(r'viewBox="([^"]+)"');
final _token = RegExp(r'[MLZ]|-?\d+(?:\.\d+)?');

/// Isolate side — plain numbers only, so the result crosses cheaply.
({List<double> viewBox, List<_RawShape> shapes}) _extract(Uint8List bytes) {
  final text = utf8.decode(bytes, allowMalformed: true);

  final box = _viewBox.firstMatch(text)?.group(1);
  final viewBox = box == null
      ? const <double>[]
      : box
            .trim()
            .split(RegExp(r'[\s,]+'))
            .map(double.tryParse)
            .whereType<double>()
            .toList();

  final shapes = <_RawShape>[];
  for (final match in _tag.allMatches(text)) {
    final attributes = {
      for (final a in _attribute.allMatches(match.group(0)!))
        a.group(1)!: a.group(2)!,
    };
    final surah = int.tryParse(attributes['surah'] ?? '');
    final ayah = int.tryParse(attributes['ayah'] ?? '');
    final polygons = _polygons(attributes['d'] ?? '');
    if (surah == null || ayah == null || polygons.isEmpty) continue;
    shapes.add((surah: surah, ayah: ayah, polygons: polygons));
  }

  return (viewBox: viewBox, shapes: shapes);
}

/// The polygon layer uses only absolute M, L and Z (checked across all 604
/// pages). A bare "x,y x,y …" point list parses the same way, as one polygon.
List<List<double>> _polygons(String d) {
  final polygons = <List<double>>[];
  var current = <double>[];

  void finish() {
    if (current.length >= 6) polygons.add(current);
    current = <double>[];
  }

  for (final match in _token.allMatches(d)) {
    final token = match.group(0)!;
    if (token == 'M' || token == 'Z') {
      finish();
    } else if (token != 'L') {
      current.add(double.parse(token));
    }
  }
  finish();

  return polygons;
}
