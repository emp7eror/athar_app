import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'globe_land_raster.dart';
import 'globe_land_texture.dart';
import 'my_world_models.dart';

/// Where the globe is looked at from. [yaw] turns it about the poles,
/// [pitch] is the latitude facing the viewer, [zoom] scales its radius.
///
/// The shader (shaders/globe.frag) and the pillar painter both read this,
/// with the same projection, so pillars stand exactly on their places.
class GlobeCamera extends ChangeNotifier {
  GlobeCamera({this.yaw = 0, this.pitch = 0.3, this.zoom = 1});

  double yaw;
  double pitch;
  double zoom;

  /// Seconds since start; drives the stars' twinkle.
  double time = 0;

  static const minZoom = 0.75;

  /// Close enough to see a coastline's detail: the land is redrawn from the
  /// SVG at screen resolution, so it stays sharp all the way in.
  static const maxZoom = 16.0;
  static const maxPitch = 1.35;

  void set({double? yaw, double? pitch, double? zoom, double? time}) {
    if (yaw != null) this.yaw = _wrap(yaw);
    if (pitch != null) this.pitch = pitch.clamp(-maxPitch, maxPitch);
    if (zoom != null) this.zoom = zoom.clamp(minZoom, maxZoom);
    if (time != null) this.time = time;
    notifyListeners();
  }

  /// [a] in -π..π, so the yaw never grows without bound while spinning.
  static double _wrap(double a) {
    const tau = 2 * math.pi;
    final r = a % tau;
    return r > math.pi ? r - tau : r;
  }

  /// The globe's radius in a canvas of [size].
  double radiusIn(Size size) => size.shortestSide * 0.42 * zoom;

  /// Projects [lat]/[lng] (degrees) into a canvas of [size]. `z` is how much
  /// the point faces the viewer: negative is behind the globe.
  ({Offset offset, double z}) project(double lat, double lng, Size size) {
    final phi = lat * math.pi / 180;
    final lambda = lng * math.pi / 180;
    final x = math.cos(phi) * math.sin(lambda);
    final y = math.sin(phi);
    final z = math.cos(phi) * math.cos(lambda);

    // Yaw about the polar axis, then pitch about the horizontal one.
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x1 = x * cy + z * sy;
    final z1 = -x * sy + z * cy;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final y2 = y * cp - z1 * sp;
    final z2 = y * sp + z1 * cp;

    final r = radiusIn(size);
    final c = size.center(Offset.zero);
    return (offset: Offset(c.dx + x1 * r, c.dy - y2 * r), z: z2);
  }

  /// The yaw and pitch that face [lat]/[lng].
  static ({double yaw, double pitch}) facing(double lat, double lng) =>
      (yaw: -lng * math.pi / 180, pitch: (lat * math.pi / 180).clamp(-maxPitch, maxPitch));
}

/// The shader and the land mask, loaded once and kept for the app's life.
/// The mask is built from the bundled SVG on first open (see
/// GlobeLandTexture); until both are ready the globe draws its plain fallback.
class _GlobeAssets {
  static Future<({ui.FragmentProgram? program, ui.Image? image})>? _loading;

  static Future<({ui.FragmentProgram? program, ui.Image? image})> load() => _loading ??= _load();

  static Future<({ui.FragmentProgram? program, ui.Image? image})> _load() async {
    ui.FragmentProgram? program;
    final image = GlobeLandTexture.load();
    try {
      program = await ui.FragmentProgram.fromAsset('shaders/globe.frag');
    } catch (_) {
      // Drawn with the plain fallback below; the pillars still work.
    }
    final result = (program: program, image: await image);
    // Tried again next open if either failed.
    if (result.program == null || result.image == null) _loading = null;
    return result;
  }
}

/// The interactive globe: drag to turn, pinch or scroll to zoom. Each place
/// with activity stands a pillar, one coloured segment per category. Tapping
/// a pillar shows its count above it; tapping it again, or the count, opens
/// its details. It turns slowly on its own unless [autoRotate] is off; a drag
/// pauses that and it resumes after a few seconds of no touch.
class MyWorldGlobe extends StatefulWidget {
  const MyWorldGlobe({
    super.key,
    required this.camera,
    required this.clusters,
    required this.autoRotate,
    required this.atmosphere,
    required this.onClusterTap,
    required this.onZoomChanged,
  });

  final GlobeCamera camera;
  final List<WorldCluster> clusters;
  final bool autoRotate;

  /// The glow around the globe: the app theme's colour.
  final Color atmosphere;

  /// Opens a pillar's details.
  final ValueChanged<WorldCluster> onClusterTap;
  final ValueChanged<double> onZoomChanged;

  @override
  State<MyWorldGlobe> createState() => _MyWorldGlobeState();
}

class _MyWorldGlobeState extends State<MyWorldGlobe> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  ui.FragmentShader? _shader;
  ui.Image? _image;

  Duration _last = Duration.zero;
  bool _interacting = false;
  Timer? _resume;
  bool _resumed = true;

  /// The platform's "reduce motion", read in build.
  bool _reduced = false;

  /// The pillar whose count is showing.
  String? _selectedId;

  /// A sharp mask of the area in view, while zoomed in; see [_checkDetail].
  GlobeLandDetail? _detail;
  bool _buildingDetail = false;
  double _sinceDetailCheck = 0;
  double _dpr = 1;

  // Gesture state.
  Offset? _lastFocal;
  double _startZoom = 1;
  Size _size = Size.zero;

  /// Radians a second when turning on its own: a full turn in ~100 s.
  static const _spinSpeed = 0.06;
  static const _resumeAfter = Duration(seconds: 4);

  WorldCluster? get _selected => widget.clusters.firstWhereOrNull((c) => c.id == _selectedId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick)..start();
    _GlobeAssets.load().then((assets) {
      if (!mounted) return;
      setState(() {
        _shader = assets.program?.fragmentShader();
        _image = assets.image;
      });
    });
  }

  @override
  void didUpdateWidget(MyWorldGlobe old) {
    super.didUpdateWidget(old);
    // New filters or a new zoom level make new pillars; the old one is gone.
    if (_selectedId != null && _selected == null) _selectedId = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resume?.cancel();
    _ticker.dispose();
    _shader?.dispose();
    _detail?.image.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No frames while the app is in the background.
    if (state == AppLifecycleState.resumed) {
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_ticker.isActive) _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    // Capped, so a dropped frame or a return from another route doesn't jump.
    final dt = _last == Duration.zero ? 0.0 : math.min(0.1, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    final reduced = _reduced;
    // A pillar's count stays put while it is read.
    final spin = widget.autoRotate && !_interacting && _resumed && _selectedId == null;
    if (spin) {
      // The same pace on screen at any zoom.
      final speed = _spinSpeed / widget.camera.zoom;
      widget.camera.set(yaw: widget.camera.yaw + speed * dt, time: reduced ? 0 : widget.camera.time + dt);
    } else if (!reduced) {
      // Keep the stars twinkling while still.
      widget.camera.set(time: widget.camera.time + dt);
    }

    _sinceDetailCheck += dt;
    if (_sinceDetailCheck >= 0.3) {
      _sinceDetailCheck = 0;
      _checkDetail();
    }
  }

  /// Keeps a sharp mask of the area in view while zoomed in. Checked a few
  /// times a second; a new one is built in the background only when the view
  /// leaves the current one or needs more resolution than it has, one at a
  /// time, and swapped in when ready (the whole-world mask shows meanwhile).
  void _checkDetail() {
    if (_size.isEmpty || _shader == null) return;
    final need = _neededDetail();
    if (need == null) {
      if (_detail != null) {
        final old = _detail;
        setState(() => _detail = null);
        old!.image.dispose();
      }
      return;
    }
    final current = _detail;
    if (current != null &&
        current.area.contains(need.inView) &&
        current.pixelsPerDegree >= need.pixelsPerDegree * 0.75) {
      return;
    }
    if (_buildingDetail) return;
    _buildingDetail = true;
    GlobeLandTexture.detail(need.area, need.width, need.height).then((detail) {
      _buildingDetail = false;
      if (detail == null) return;
      if (!mounted) {
        detail.image.dispose();
        return;
      }
      final old = _detail;
      setState(() => _detail = detail);
      old?.image.dispose();
      // The view may have moved on while it was built.
      _sinceDetailCheck = 0.3;
    });
  }

  /// The area to draw sharply and at what size, or null when the whole-world
  /// mask is already as sharp as the screen.
  ({LandArea area, LandArea inView, int width, int height, double pixelsPerDegree})? _neededDetail() {
    final cam = widget.camera;
    final radius = cam.radiusIn(_size);
    // Physical pixels a degree spans at the centre of the view.
    final ppd = radius * _dpr * math.pi / 180;
    if (ppd <= GlobeLandRaster.width / 360 * 1.25) return null;

    // How far from the centre of the view the screen reaches, as an angle on
    // the sphere (a point d from the centre sits asin(d/R) away).
    final reach = _size.center(Offset.zero).distance / radius;
    if (reach >= 0.95) return null;
    final theta = math.asin(reach) * 180 / math.pi;
    final lat = cam.pitch * 180 / math.pi;
    final lon = -cam.yaw * 180 / math.pi;

    LandArea around(double half) {
      final top = math.min(90.0, lat + half);
      final bottom = math.max(-90.0, lat - half);
      final cosFar = math.cos(math.max(top.abs(), bottom.abs()) * math.pi / 180);
      // Near a pole every longitude is in view.
      final lonHalf = (top >= 90 || bottom <= -90 || cosFar < 0.1) ? 180.0 : math.min(180.0, half / cosFar);
      return LandArea(
        lonHalf >= 180 ? 0 : (lon - lonHalf + 180) / 360,
        (90 - top) / 180,
        lonHalf >= 180 ? 1 : lonHalf * 2 / 360,
        (top - bottom) / 180,
      );
    }

    // Built with a margin, so small pans and turns don't need a new one.
    final area = around(theta * 1.4);
    final inView = around(theta);

    // Along a parallel, a degree is shortest on screen at the area's edge
    // farthest from the equator, and longest at the one nearest it.
    final top = 90 - area.v0 * 180, bottom = top - area.dv * 180;
    final nearEquator = (top >= 0 && bottom <= 0) ? 0.0 : math.min(top.abs(), bottom.abs());
    final cosNear = math.cos(nearEquator * math.pi / 180);
    final height = (area.dv * 180 * ppd).ceil().clamp(64, GlobeLandRaster.maxDetailSide);
    final width = (area.du * 360 * ppd * cosNear).ceil().clamp(64, GlobeLandRaster.maxDetailSide);
    return (area: area, inView: inView, width: width, height: height, pixelsPerDegree: ppd);
  }

  void _pauseSpin() {
    _resume?.cancel();
    _resumed = false;
  }

  void _scheduleResume() {
    _resume?.cancel();
    _resume = Timer(_resumeAfter, () => _resumed = true);
  }

  void _onScaleStart(ScaleStartDetails d) {
    _interacting = true;
    _pauseSpin();
    _lastFocal = d.localFocalPoint;
    _startZoom = widget.camera.zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final cam = widget.camera;
    final radius = cam.radiusIn(_size);
    final last = _lastFocal ?? d.localFocalPoint;
    final delta = d.localFocalPoint - last;
    _lastFocal = d.localFocalPoint;

    // Moving a finger by one radius turns the globe by about a radian.
    cam.set(
      yaw: cam.yaw + delta.dx / radius,
      pitch: cam.pitch + delta.dy / radius,
      zoom: d.pointerCount > 1 ? _startZoom * d.scale : null,
    );
    if (d.pointerCount > 1) widget.onZoomChanged(cam.zoom);
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _interacting = false;
    _lastFocal = null;
    _scheduleResume();
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      final cam = widget.camera;
      cam.set(zoom: cam.zoom * math.exp(-e.scrollDelta.dy / 400));
      widget.onZoomChanged(cam.zoom);
      _pauseSpin();
      _scheduleResume();
    }
  }

  /// The pillar under the finger, its column or its base. Taps win over drags
  /// since the tap recogniser only fires when the finger didn't travel.
  WorldCluster? _hit(Offset position) {
    WorldCluster? best;
    var bestDistance = double.infinity;
    for (final c in widget.clusters) {
      final g = PillarStyle.geometry(c, widget.camera, _size);
      if (g == null) continue;
      // At least a finger's width to aim at, however thin the pillar.
      final reach = math.max(22.0, g.width) / 2 + 6;
      final dx = (position.dx - g.base.dx).abs();
      final withinColumn = dx <= reach && position.dy >= g.top.dy - 10 && position.dy <= g.base.dy + 12;
      if (!withinColumn) continue;
      final distance = (position - g.base).distance;
      if (distance < bestDistance) {
        best = c;
        bestDistance = distance;
      }
    }
    return best;
  }

  void _onTapUp(TapUpDetails d) {
    final hit = _hit(d.localPosition);
    if (hit == null) {
      if (_selectedId != null) setState(() => _selectedId = null);
      return;
    }
    _pauseSpin();
    _scheduleResume();
    if (hit.id == _selectedId) {
      widget.onClusterTap(hit);
    } else {
      setState(() => _selectedId = hit.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    _reduced = MediaQuery.disableAnimationsOf(context);
    _dpr = MediaQuery.devicePixelRatioOf(context);
    final selected = _selected;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Listener(
                onPointerSignal: _onPointerSignal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  onTapUp: _onTapUp,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _GlobePainter(
                        camera: widget.camera,
                        shader: _shader,
                        image: _image,
                        clusters: widget.clusters,
                        selectedId: _selectedId,
                        detail: _detail,
                        atmosphere: widget.atmosphere,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (selected != null)
              // Follows the pillar as the globe turns; above the gestures, so a
              // tap on it opens the details.
              AnimatedBuilder(
                animation: widget.camera,
                builder: (context, _) {
                  final g = PillarStyle.geometry(selected, widget.camera, _size);
                  if (g == null) return const SizedBox.shrink();
                  return Positioned(
                    left: g.top.dx,
                    top: g.top.dy - 8,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -1),
                      child: _CountLabel(
                        total: selected.total,
                        opacity: g.facing,
                        onTap: () => widget.onClusterTap(selected),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// The count above a tapped pillar, with a chevron: tapping it opens the
/// place's details.
class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.total, required this.opacity, required this.onTap});

  final int total;
  final double opacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = 'my_world_cluster_total'.trParams({'count': '$total'});
    return Opacity(
      opacity: opacity,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: context.athar.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: context.colors.outlineVariant),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$total',
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 18, color: AtharTone.brand.foreground(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a pillar is drawn on screen this frame.
typedef PillarGeometry = ({Offset base, Offset top, double width, double height, double facing});

/// Pillar sizes. Height follows the server's 0..1 log-scaled intensity, so a
/// place with one record still shows and the largest never dwarfs the rest.
///
/// Pillars stand upright on the screen from their place on the surface. A
/// pillar pointing straight out of the sphere would shrink to a dot when its
/// place faces the viewer — which the home view does for the main place.
abstract final class PillarStyle {
  static const minHeight = 14.0;
  static const maxHeight = 84.0;

  static double _zoomScale(double zoom) => math.sqrt(zoom).clamp(1.0, 1.6);

  static double height(double intensity, double zoom) =>
      (minHeight + (maxHeight - minHeight) * intensity) * _zoomScale(zoom);

  static double width(double zoom) => 9 * _zoomScale(zoom);

  /// [c]'s pillar this frame, or null when its place is behind the globe.
  static PillarGeometry? geometry(WorldCluster c, GlobeCamera camera, Size size) {
    final p = camera.project(c.lat, c.lng, size);
    // Fades out towards the limb, gone behind the globe.
    final facing = ((p.z - 0.02) / 0.18).clamp(0.0, 1.0);
    if (facing <= 0) return null;
    final h = height(c.intensity, camera.zoom);
    return (base: p.offset, top: p.offset - Offset(0, h), width: width(camera.zoom), height: h, facing: facing);
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({
    required this.camera,
    required this.shader,
    required this.image,
    required this.clusters,
    required this.selectedId,
    required this.detail,
    required this.atmosphere,
  }) : super(repaint: camera);

  final GlobeCamera camera;
  final ui.FragmentShader? shader;
  final ui.Image? image;
  final List<WorldCluster> clusters;
  final String? selectedId;
  final GlobeLandDetail? detail;
  final Color atmosphere;

  /// [atmosphere] at full brightness, keeping its hue: a dark theme colour
  /// would otherwise barely glow against the night sky.
  List<double> get _glow {
    final c = [atmosphere.r, atmosphere.g, atmosphere.b];
    final peak = c.reduce(math.max);
    return peak < 0.01 ? [1, 1, 1] : [for (final v in c) v / peak];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = camera.radiusIn(size);

    final s = shader;
    final img = image;
    if (s != null && img != null) {
      s
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, center.dx)
        ..setFloat(3, center.dy)
        ..setFloat(4, radius)
        ..setFloat(5, camera.yaw)
        ..setFloat(6, camera.pitch)
        ..setFloat(7, camera.time)
        ..setFloat(8, _glow[0])
        ..setFloat(9, _glow[1])
        ..setFloat(10, _glow[2]);
      final d = detail;
      s
        ..setFloat(11, d?.area.u0 ?? 0)
        ..setFloat(12, d?.area.v0 ?? 0)
        ..setFloat(13, d?.area.du ?? 1)
        ..setFloat(14, d?.area.dv ?? 1)
        ..setFloat(15, d == null ? 0 : 1)
        // Smooth sampling; the default (nearest) shows blocky coastlines.
        // Mipmaps for the whole world, which is drawn smaller than it is.
        ..setImageSampler(0, img, filterQuality: FilterQuality.medium)
        // Every sampler must be set: the world stands in when there's no detail.
        ..setImageSampler(1, d?.image ?? img, filterQuality: FilterQuality.low);
      canvas.drawRect(rect, Paint()..shader = s);
    } else {
      _fallback(canvas, rect, center, radius);
    }

    _pillars(canvas, size);
  }

  /// A plain globe while the shader loads, or if it can't run here.
  void _fallback(Canvas canvas, Rect rect, Offset center, double radius) {
    canvas.drawRect(rect, Paint()..color = const Color(0xFF000000));
    canvas.drawCircle(
      center,
      radius * 1.08,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius * 1.08,
          [atmosphere.withValues(alpha: 0.33), atmosphere.withValues(alpha: 0)],
          [0.9, 1.0],
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(center - Offset(radius * 0.3, radius * 0.3), radius * 1.3, [
          const Color(0xFF1A2A55),
          const Color(0xFF060B1E),
        ]),
    );
  }

  void _pillars(Canvas canvas, Size size) {
    final placed = <(WorldCluster, PillarGeometry)>[
      for (final c in clusters)
        if (PillarStyle.geometry(c, camera, size) case final g?) (c, g),
    ];
    // Farther up the screen is farther back: those draw first.
    placed.sort((a, b) => a.$2.base.dy.compareTo(b.$2.base.dy));
    for (final (c, g) in placed) {
      _pillar(canvas, c, g, selected: c.id == selectedId);
    }
  }

  void _pillar(Canvas canvas, WorldCluster c, PillarGeometry g, {required bool selected}) {
    // Approximate places (country only) stand fainter.
    final alpha = g.facing * (c.approximate ? 0.6 : 1.0);
    final w = g.width;
    final half = w / 2;
    final capHeight = w * 0.45;

    // A shadow where it meets the ground.
    canvas.drawOval(
      Rect.fromCenter(center: g.base, width: w * 2.2, height: w * 0.8),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, 0.45 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    if (c.approximate) {
      _dashedOval(canvas, Rect.fromCenter(center: g.base, width: w * 3.2, height: w * 1.2), alpha);
    }

    // Segments bottom-up in the categories' order, each its share of the height.
    final segments = [
      for (final cat in WorldCategory.all)
        if ((c.counts[cat.id] ?? 0) > 0) (cat.color, c.counts[cat.id]!),
    ];
    final sum = segments.fold<int>(0, (a, s) => a + s.$2);
    if (sum == 0) return;

    final body = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(g.base.dx - half, g.top.dy, g.base.dx + half, g.base.dy),
          bottomLeft: Radius.elliptical(half, capHeight / 2),
          bottomRight: Radius.elliptical(half, capHeight / 2),
        ),
      );

    canvas.save();
    canvas.clipPath(body);
    var y = g.base.dy;
    Color topColor = segments.last.$1;
    for (final (color, n) in segments) {
      final h = g.height * n / sum;
      final rect = Rect.fromLTRB(g.base.dx - half, y - h, g.base.dx + half, y);
      // Lit from the upper left like the globe: a round column, not a flat bar.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.centerLeft,
            rect.centerRight,
            [
              Color.lerp(color, const Color(0xFFFFFFFF), 0.25)!.withValues(alpha: alpha),
              color.withValues(alpha: alpha),
              Color.lerp(color, const Color(0xFF000000), 0.45)!.withValues(alpha: alpha),
            ],
            [0.0, 0.45, 1.0],
          ),
      );
      // A hairline between segments.
      if (y < g.base.dy) {
        canvas.drawLine(
          Offset(rect.left, y),
          Offset(rect.right, y),
          Paint()
            ..color = Color.fromRGBO(4, 8, 23, 0.55 * alpha)
            ..strokeWidth = 1,
        );
      }
      y -= h;
      topColor = color;
    }
    canvas.restore();

    // The top cap: the column seen slightly from above.
    canvas.drawOval(
      Rect.fromCenter(center: g.top, width: w, height: capHeight),
      Paint()..color = Color.lerp(topColor, const Color(0xFFFFFFFF), 0.35)!.withValues(alpha: alpha),
    );

    if (selected) {
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.fromRGBO(255, 255, 255, 0.9 * g.facing);
      canvas.drawPath(body, outline);
      canvas.drawOval(Rect.fromCenter(center: g.top, width: w, height: capHeight), outline);
    }
  }

  void _dashedOval(Canvas canvas, Rect oval, double alpha) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Color.fromRGBO(230, 236, 255, 0.6 * alpha);
    const dashes = 14;
    const sweep = math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(oval, i * 2 * sweep, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.shader != shader ||
      old.image != image ||
      old.clusters != clusters ||
      old.selectedId != selectedId ||
      old.detail != detail ||
      old.atmosphere != atmosphere;
}
