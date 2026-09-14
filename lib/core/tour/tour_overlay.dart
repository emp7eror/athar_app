import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
import 'tour_models.dart';
import 'tour_service.dart';

/// Transparent route that hosts the spotlight. Being a route means Android
/// back skips the tour, the overlay covers the nav bar, and the page underneath
/// can't be touched until the tour closes.
class TourRoute extends PopupRoute<TourOutcome> {
  TourRoute({required this.tour, required this.service});

  final PageTour tour;
  final TourService service;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      TourOverlay(tour: tour, service: service);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
}

class TourOverlay extends StatefulWidget {
  const TourOverlay({super.key, required this.tour, required this.service});

  final PageTour tour;
  final TourService service;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Brand ink at ~78%.
  static const _dim = Color(0xC70C130F);

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  Rect? _from;
  Rect? _target;
  int _index = -1;
  bool _preparing = true;
  bool _closing = false;
  bool _navigated = false;

  /// Bumped whenever a step starts or the tour closes, so a slow step
  /// preparation that finishes late doesn't overwrite a newer one.
  int _token = 0;

  /// Keeps the spotlight glued to its element if the layout shifts.
  Timer? _tracker;

  List<TourStep> get _steps => widget.tour.steps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(0));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tracker?.cancel();
    _move.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Rotation, window resize, split screen: re-measure once the layout settles.
  @override
  void didChangeMetrics() {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _index >= 0) _refresh(scroll: true);
    });
  }

  // ── Geometry ───────────────────────────────────────────────────────

  Rect? get _currentRect {
    final target = _target;
    if (target == null) return null;
    final from = _from;
    if (from == null) return target;
    return Rect.lerp(from, target, Curves.easeOutCubic.transform(_move.value));
  }

  Rect _holeFor(Rect r, TourStep step) => step.shape == TourShape.circle
      ? Rect.fromCircle(center: r.center, radius: r.longestSide / 2 + step.padding)
      : r.inflate(step.padding);

  Rect? get _hole {
    final r = _currentRect;
    return r == null || _index < 0 ? null : _holeFor(r, _steps[_index]);
  }

  /// The element's rect in this overlay's coordinates, or null if it isn't
  /// laid out — or, with [onScreen], if it's entirely off screen. Off-screen
  /// elements further down a list are still valid before they're scrolled to.
  Rect? _measure(BuildContext target, {bool onScreen = true}) {
    final box = target.findRenderObject();
    final overlay = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (overlay is! RenderBox || !overlay.hasSize) return null;

    final topLeft = overlay.globalToLocal(box.localToGlobal(Offset.zero));
    final rect = topLeft & box.size;
    if (rect.isEmpty || !rect.isFinite) return null;
    if (onScreen && !(Offset.zero & overlay.size).overlaps(rect)) return null;
    return rect;
  }

  /// Inside the safe area and clear of the floating nav bar.
  bool _comfortablyVisible(Rect r) {
    final mq = MediaQuery.of(context);
    final safe = Rect.fromLTRB(
      0,
      mq.padding.top + 8,
      mq.size.width,
      mq.size.height - mq.padding.bottom - 96,
    );
    return safe.contains(r.topLeft) && safe.contains(r.bottomRight);
  }

  // ── Steps ──────────────────────────────────────────────────────────

  Future<void> _show(int from) async {
    final token = ++_token;
    _tracker?.cancel();
    if (mounted) setState(() => _preparing = true);

    for (var i = from; i < _steps.length; i++) {
      final rect = await _prepare(_steps[i]);
      if (!mounted || token != _token || _closing) return;
      if (rect == null) continue; // target not on screen → skip this step

      setState(() {
        _from = _currentRect ?? _entryRect(rect);
        _target = rect;
        _index = i;
        _preparing = false;
      });
      _move.forward(from: 0);
      _tracker = Timer.periodic(
        const Duration(milliseconds: 450),
        (_) => _refresh(),
      );
      return;
    }

    // Nothing (left) to show.
    _close(_index < 0 ? TourOutcome.aborted : TourOutcome.completed);
  }

  /// A huge rect around the first target, so the spotlight "closes in" on it.
  Rect _entryRect(Rect r) {
    final side = MediaQuery.sizeOf(context).longestSide * 2.4;
    return Rect.fromCenter(center: r.center, width: side, height: side);
  }

  /// Navigates if the step asks to, waits for its element to exist, scrolls
  /// it into view, then measures it.
  Future<Rect?> _prepare(TourStep step) async {
    final service = widget.service;

    if (step.navigateTo != null && await service.navigateTo(step.navigateTo!)) {
      _navigated = true;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    BuildContext? target;
    for (var attempt = 0; attempt < 25; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return null;
      final ctx = service.contextFor(step.target);
      if (ctx != null && ctx.mounted && _measure(ctx, onScreen: false) != null) {
        target = ctx;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    if (target == null || !target.mounted) return null;

    final before = _measure(target, onScreen: false);
    if (before != null && !_comfortablyVisible(before)) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted || !target.mounted) return null;
    return _measure(target);
  }

  Future<void> _refresh({bool scroll = false}) async {
    if (!mounted || _index < 0 || _closing || _preparing) return;
    var ctx = widget.service.contextFor(_steps[_index].target);
    if (ctx == null) return;

    if (scroll) {
      final r = _measure(ctx);
      if (r != null && !_comfortablyVisible(r)) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.3,
          duration: const Duration(milliseconds: 250),
        );
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted || !ctx.mounted) return;
    }

    final r = _measure(ctx);
    final target = _target;
    if (r == null || target == null) return;
    final moved = (r.topLeft - target.topLeft).distance > 1 ||
        (r.width - target.width).abs() > 1 ||
        (r.height - target.height).abs() > 1;
    if (!moved) return;

    setState(() {
      _from = _currentRect;
      _target = r;
    });
    _move.forward(from: 0);
  }

  void _next() {
    if (_closing || _preparing) return;
    if (_index + 1 >= _steps.length) {
      _close(TourOutcome.completed);
    } else {
      _show(_index + 1);
    }
  }

  Future<void> _close(TourOutcome outcome) async {
    if (_closing) return;
    _closing = true;
    _token++;
    _tracker?.cancel();

    // A step switched tabs — come back to the page the tour belongs to.
    if (_navigated) await widget.service.navigateTo(widget.tour.pageId);
    if (mounted) Navigator.of(context).pop(outcome);
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final gold = context.athar.gold;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(TourOutcome.skipped);
      },
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    // Swallows every touch so the page underneath can't be
                    // used mid-tour; tapping the highlighted element advances.
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final hole = _hole;
                      if (hole != null && hole.contains(details.localPosition)) {
                        _next();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_move, _pulse]),
                      builder: (context, _) => CustomPaint(
                        size: size,
                        painter: _SpotlightPainter(
                          hole: _hole,
                          circle: _index >= 0 &&
                              _steps[_index].shape == TourShape.circle,
                          radius: _index >= 0 ? _steps[_index].radius : 0,
                          dim: _dim,
                          accent: gold,
                          pulse: _pulse.value,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_index >= 0 && _target != null)
                  _positionedCard(size, padding, _holeFor(_target!, _steps[_index])),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Puts the coach mark below the spotlight when there's room, above it
  /// otherwise, clamped inside the safe area on any screen size.
  Widget _positionedCard(Size size, EdgeInsets pad, Rect hole) {
    const margin = 16.0;
    const gap = 16.0;
    const estimatedHeight = 210.0;

    final width = math.min(size.width - margin * 2, 420.0);
    final left = (hole.center.dx - width / 2)
        .clamp(margin, math.max(margin, size.width - width - margin))
        .toDouble();

    final spaceBelow = size.height - pad.bottom - hole.bottom;
    final spaceAbove = hole.top - pad.top;
    final below = spaceBelow >= estimatedHeight + gap || spaceBelow >= spaceAbove;
    final fits = (below ? spaceBelow : spaceAbove) >= estimatedHeight + gap;

    final minTop = pad.top + margin;
    final maxTop = math.max(minTop, size.height - pad.bottom - margin - estimatedHeight);
    final minBottom = pad.bottom + margin;
    final maxBottom = math.max(minBottom, size.height - pad.top - margin - estimatedHeight);

    return Positioned(
      left: left,
      width: width,
      top: below ? (hole.bottom + gap).clamp(minTop, maxTop).toDouble() : null,
      bottom: below
          ? null
          : (size.height - hole.top + gap).clamp(minBottom, maxBottom).toDouble(),
      child: AnimatedOpacity(
        opacity: _preparing ? 0 : 1,
        duration: const Duration(milliseconds: 180),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: Offset(0, below ? -0.04 : 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _CoachMark(
            key: ValueKey(_index),
            step: _steps[_index],
            index: _index,
            total: _steps.length,
            arrow: fits ? (below ? _ArrowSide.top : _ArrowSide.bottom) : null,
            arrowX: (hole.center.dx - left).clamp(28.0, width - 28.0).toDouble(),
            onNext: _next,
            onSkip: () => _close(TourOutcome.skipped),
          ),
        ),
      ),
    );
  }
}

enum _ArrowSide { top, bottom }

class _CoachMark extends StatelessWidget {
  const _CoachMark({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.arrow,
    required this.arrowX,
    required this.onNext,
    required this.onSkip,
  });

  final TourStep step;
  final int index;
  final int total;
  final _ArrowSide? arrow;

  /// Arrow position from the card's physical left edge.
  final double arrowX;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final isLast = index == total - 1;
    final border = athar.gold.withValues(alpha: 0.35);

    final card = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: athar.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: athar.gold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.icon ?? Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: athar.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.titleKey.tr,
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'tour_step_of'.trParams({'current': '${index + 1}', 'total': '$total'}),
                style: context.text.labelMedium?.copyWith(
                  color: athar.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.bodyKey.tr,
            style: context.text.bodyMedium?.copyWith(color: athar.textMuted, height: 1.55),
          ),
          const SizedBox(height: 12),
          // Dots on the leading side, actions on the trailing side. On narrow
          // screens or with large text the actions drop to their own line and
          // stack, instead of overflowing.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                _Dots(index: index, total: total),
                OverflowBar(
                  spacing: 4,
                  overflowSpacing: 4,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: [
                    if (!isLast)
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(foregroundColor: athar.textMuted),
                        child: Text('tour_skip'.tr),
                      ),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(isLast ? 'tour_done'.tr : 'tour_next'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final side = arrow;
    return Semantics(
      container: true,
      liveRegion: true,
      child: side == null
          ? card
          : Stack(
              clipBehavior: Clip.none,
              children: [
                card,
                Positioned(
                  left: arrowX - 9,
                  top: side == _ArrowSide.top ? -8.5 : null,
                  bottom: side == _ArrowSide.bottom ? -8.5 : null,
                  child: CustomPaint(
                    size: const Size(18, 9),
                    painter: _ArrowPainter(
                      fill: athar.card,
                      border: border,
                      up: side == _ArrowSide.top,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsetsDirectional.only(end: 4),
            width: i == index ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? athar.gold : athar.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.fill, required this.border, required this.up});

  final Color fill;
  final Color border;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height))
        : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0));
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.fill != fill || old.border != border || old.up != up;
}

/// Dims the screen and cuts a clean hole around the target, with a gold
/// outline and a soft pulse ring.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.circle,
    required this.radius,
    required this.dim,
    required this.accent,
    required this.pulse,
  });

  final Rect? hole;
  final bool circle;
  final double radius;
  final Color dim;
  final Color accent;
  final double pulse;

  Path _shape(Rect r, double grow) {
    final rect = r.inflate(grow);
    return circle
        ? (Path()..addOval(rect))
        : (Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius + grow))));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, Paint()..color = dim);
    final h = hole;
    if (h != null) {
      canvas.drawPath(_shape(h, 0), Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();

    if (h == null) return;
    canvas.drawPath(
      _shape(h, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = accent.withValues(alpha: 0.9),
    );
    canvas.drawPath(
      _shape(h, 10 * pulse),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.45 * (1 - pulse)),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => true;
}
