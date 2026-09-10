import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which way the page goes.
enum TurnDirection { forward, backward }

/// Turns Mushaf pages with a short, plain flip.
///
/// The gesture is a swipe, not a drag: nothing moves while the finger is on the
/// screen. Lifting it either turns the page or does nothing at all. This is
/// deliberate — driving the paper from the finger meant the half of the page
/// that hadn't been reached stayed flat and undistorted next to the page
/// underneath, which read as the two facing pages of an open book.
///
/// The flip itself is one rotation of the outgoing sheet about the binding,
/// with a little perspective and a shadow. No mesh, no curl, no bending.
class PageTurn extends StatefulWidget {
  const PageTurn({
    super.key,
    required this.page,
    required this.pageBuilder,
    required this.canTurn,
    required this.onTurned,
    this.duration = const Duration(milliseconds: 340),
  });

  /// The page on top.
  final int page;

  /// Builds the sheet for a given page number.
  final Widget Function(BuildContext context, int page) pageBuilder;

  final bool Function(TurnDirection direction) canTurn;
  final void Function(TurnDirection direction) onTurned;

  final Duration duration;

  @override
  State<PageTurn> createState() => PageTurnState();
}

class PageTurnState extends State<PageTurn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  TurnDirection _direction = TurnDirection.forward;

  /// The page sliding out from under the turning sheet.
  int? _outgoing;

  /// A swipe has to travel this far, or be thrown this fast, to count.
  static const _minTravel = 40.0;
  static const _minVelocity = 260.0;

  double _travelled = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStart(DragStartDetails details) => _travelled = 0;

  void _onUpdate(DragUpdateDetails details) => _travelled += details.delta.dx;

  void _onEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;

    // Reading onward in an RTL Mushaf carries the free left edge rightward.
    final wantsForward = _travelled > 0;
    final far = _travelled.abs() >= _minTravel;
    final fast = velocity.abs() >= _minVelocity && velocity.sign == _travelled.sign;

    if (!far && !fast) return;

    turn(wantsForward ? TurnDirection.forward : TurnDirection.backward);
  }

  /// Turns the page — used by the swipe and by the Prev/Next controls alike.
  Future<void> turn(TurnDirection direction) async {
    if (_controller.isAnimating) return;
    if (!widget.canTurn(direction)) return;

    final from = widget.page;

    setState(() {
      _direction = direction;
      _outgoing = from;
    });

    widget.onTurned(direction);

    await _controller.forward(from: 0);

    if (!mounted) return;
    setState(() => _outgoing = null);
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onStart,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final outgoing = _outgoing;
          if (outgoing == null) {
            return widget.pageBuilder(context, widget.page);
          }

          final t = Curves.easeInOut.transform(_controller.value);

          // Forward: the page just left swings away, uncovering the new one.
          // Backward: the arriving page swings in over the one being left.
          final forward = _direction == TurnDirection.forward;
          final beneath = forward ? widget.page : outgoing;
          final sheet = forward ? outgoing : widget.page;
          final lift = forward ? t : 1 - t;

          return Stack(
            fit: StackFit.expand,
            children: [
              widget.pageBuilder(context, beneath),
              _Sheet(lift: lift, child: widget.pageBuilder(context, sheet)),
            ],
          );
        },
      ),
    );
  }
}

/// The outgoing sheet, rotated about the binding on the right.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.lift, required this.child});

  /// 0 flat, 1 fully turned away.
  final double lift;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Past upright the sheet is edge-on and then hidden behind the spine.
    if (lift >= 1) return const SizedBox.shrink();

    final angle = lift * math.pi / 2;

    return Transform(
      alignment: Alignment.centerRight, // the binding
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012) // perspective: the far edge shrinks
        ..rotateY(angle),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          // The sheet loses the light as it tips away.
          IgnorePointer(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.28 * lift)),
          ),
        ],
      ),
    );
  }
}
