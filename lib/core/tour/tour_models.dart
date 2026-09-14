import 'package:flutter/widgets.dart';

/// Shape of the spotlight cut out around a target.
enum TourShape { roundedRect, circle }

/// How a tour ended.
enum TourOutcome {
  /// The user reached the last step and tapped Done.
  completed,

  /// The user tapped Skip or pressed back.
  skipped,

  /// Nothing could be shown (no target on screen, page left) — the tour is
  /// not marked as seen, so it will try again next time.
  aborted,
}

/// One coach mark: which element to highlight and what to say about it.
///
/// Pure configuration — no widgets, no controllers — so tours live apart from
/// the UI (see `lib/modules/tour/app_tours.dart`).
@immutable
class TourStep {
  const TourStep({
    required this.target,
    required this.titleKey,
    required this.bodyKey,
    this.icon,
    this.shape = TourShape.roundedRect,
    this.padding = 8,
    this.radius = 18,
    this.navigateTo,
  });

  /// Id of the `TourTarget` widget to highlight. A step whose target isn't on
  /// screen (e.g. an empty list) is skipped automatically.
  final String target;

  /// Translation keys for the coach mark's title and description.
  final String titleKey;
  final String bodyKey;

  /// Small icon shown in the coach mark.
  final IconData? icon;

  final TourShape shape;

  /// Space between the element and the edge of the spotlight.
  final double padding;

  /// Corner radius for [TourShape.roundedRect].
  final double radius;

  /// A page id to switch to before this step (e.g. another tab). The tour
  /// returns to its own page when it ends.
  final String? navigateTo;
}

/// The tour of one page.
@immutable
class PageTour {
  const PageTour({
    required this.pageId,
    required this.steps,
    this.isTab = false,
  });

  /// Stable id — also the key its completion is saved under.
  final String pageId;

  final List<TourStep> steps;

  /// Whether the page lives in the shell's tab stack. Tab pages stay mounted
  /// while hidden, so their tour only runs while their tab is the selected one.
  final bool isTab;
}
