import 'package:flutter/material.dart';

import 'page_view_mode.dart';
import 'reading_direction.dart';
import 'flip_settings.dart';
import 'paper_boundary_decoration.dart';
import 'page_flip_controller.dart';
import 'turnable_page_view.dart';

class TurnablePage extends StatelessWidget {
  final PageFlipController? controller;
  final TurnableBuilder builder;
  final int pageCount;
  final TurnablePageCallback? onPageChanged;
  final FlipSettings settings;
  final PageViewMode pageViewMode;
  final bool autoResponseSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final double? aspectRatio;
  final bool pagesBoundaryIsEnabled;

  /// Which side the book is bound on. Left-bound by default, as upstream.
  final TurnableReadingDirection readingDirection;

  TurnablePage({
    super.key,
    this.controller,
    this.aspectRatio,
    required this.builder,
    required this.pageCount,
    this.onPageChanged,
    this.pageViewMode = PageViewMode.single,
    this.autoResponseSize = true,
    this.paperBoundaryDecoration = PaperBoundaryDecoration.vintage,
    FlipSettings? settings,
    this.pagesBoundaryIsEnabled = true,
    this.readingDirection = TurnableReadingDirection.leftToRight,
  }) : settings = settings ?? FlipSettings() {
    if (settings != null) {
      assert(
        this.settings.startPageIndex >= 0,
        'Page count must be greater than 0',
      );
      assert(
        this.settings.startPageIndex < pageCount,
        'Start page index must be less than page count',
      );
    }
  }

  Size _calculateBookSize({
    required double maxWidth,
    required double maxHeight,
    required double aspectRatio,
  }) {
    double height = maxWidth / aspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      maxWidth = height * aspectRatio;
    }
    return Size(maxWidth, height);
  }

  double _getAspectRatio(bool isMobile) {
    if (!autoResponseSize && pageViewMode == PageViewMode.single) {
      return aspectRatio ?? 2 / 3;
    }
    if (pageViewMode == PageViewMode.single) {
      return aspectRatio ?? 2 / 3 * (isMobile ? 1 : 2);
    }
    return aspectRatio ?? (2 / 3) * 2;
  }

  FlipSettings _getAdjustedSetting(bool isMobile) {
    if (!autoResponseSize && pageViewMode == PageViewMode.single) {
      return settings.copyWith(usePortrait: true);
    }
    final usePortrait = pageViewMode == PageViewMode.single && isMobile;
    return settings.copyWith(usePortrait: usePortrait);
  }

  /// A right-bound book is the left-bound one seen in a mirror.
  ///
  /// The flip geometry, the shadows, the corner triggers and the swipe
  /// directions are all reflected together, so the whole interaction inverts
  /// consistently — a forward turn drags the free edge rightward, off the
  /// left-hand side, which is how a Mushaf turns. Each page's own content is
  /// then reflected a second time so the script itself reads the right way
  /// round. Reflecting the finished book is what keeps this to one place
  /// instead of a signed axis threaded through the flip maths.
  static Widget _mirror(Widget child) => Transform(
    alignment: Alignment.center,
    transform: Matrix4.diagonal3Values(-1, 1, 1),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final rightToLeft = readingDirection == TurnableReadingDirection.rightToLeft;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final aspectRatio = _getAspectRatio(isMobile);
        FlipSettings adjustedSettings = _getAdjustedSetting(isMobile);

        final bookSize = _calculateBookSize(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          aspectRatio: aspectRatio,
        );
        adjustedSettings = adjustedSettings.copyWith(
          width: bookSize.width,
          height: bookSize.height,
        );

        final book = TurnablePageView(
          builder: (context, index) {
            final page = builder(context, index, constraints);
            return rightToLeft ? _mirror(page) : page;
          },
          bookSize: bookSize,
          settings: adjustedSettings,
          pageCount: pageCount,
          controller: controller,
          aspectRatio: aspectRatio,
          onPageChanged: onPageChanged,
          pagesBoundaryIsEnabled: pagesBoundaryIsEnabled,
          paperBoundaryDecoration: paperBoundaryDecoration,
        );

        return rightToLeft ? _mirror(book) : book;
      },
    );
  }
}

typedef TurnableBuilder =
    Widget Function(
      BuildContext context,
      int pageIndex,
      BoxConstraints constraints,
    );
typedef TurnablePageCallback =
    void Function(int leftPageIndex, int rightPageIndex);
typedef PageWidgetBuilder = Widget Function(BuildContext context, int index);
