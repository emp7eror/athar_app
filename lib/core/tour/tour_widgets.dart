import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../design/athar_scale.dart';
import '../theme/app_theme.dart';
import 'tour_service.dart';

TourService? get _tours =>
    Get.isRegistered<TourService>() ? Get.find<TourService>() : null;

/// Marks [child] as a spotlight target a tour step can point at by [id].
///
/// Adds nothing to layout. Wrap the element itself — inside `Expanded`,
/// `Positioned` etc., never around them.
class TourTarget extends StatefulWidget {
  const TourTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  @override
  void initState() {
    super.initState();
    _tours?.register(widget.id, this);
  }

  @override
  void didUpdateWidget(TourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _tours?.unregister(oldWidget.id, this);
      _tours?.register(widget.id, this);
    }
  }

  @override
  void dispose() {
    _tours?.unregister(widget.id, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum TourHelpStyle {
  /// Round card button, for custom page headers.
  circle,

  /// Plain icon button, for `AppBar.actions`.
  appBar,
}

/// The Help (?) button that replays [pageId]'s tour. Renders nothing when the
/// page has no tour. It is itself a target (`<pageId>.help`), so a tour can end
/// by pointing at it.
class TourHelpButton extends StatelessWidget {
  const TourHelpButton({
    super.key,
    required this.pageId,
    this.style = TourHelpStyle.circle,
  });

  final String pageId;
  final TourHelpStyle style;

  static String targetId(String pageId) => '$pageId.help';

  @override
  Widget build(BuildContext context) {
    final service = _tours;
    if (service == null || !service.hasTour(pageId)) return const SizedBox.shrink();
    final size = 22 * AtharScale.of(context).clamp(1.0, 1.2);

    void replay() {
      if (service.running.value != null) return;
      service.start(pageId, context, replay: true);
    }

    final Widget button = switch (style) {
      TourHelpStyle.appBar => IconButton(
          onPressed: replay,
          tooltip: 'tour_help'.tr,
          icon: const Icon(Icons.help_outline_rounded),
        ),

      TourHelpStyle.circle => Tooltip(
          message: 'tour_help'.tr,
          child: InkWell(
            onTap: replay,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.help,
                size: size,
                color: context.colors.primary,
              ),
            ),
          ),
        ),
    };

    return TourTarget(id: targetId(pageId), child: button);
  }
}

/// Starts [pageId]'s tour on the first visit to a pushed page (a route of its
/// own, e.g. Dhikr or the Quran).
class TourAutoStart extends StatefulWidget {
  const TourAutoStart({super.key, required this.pageId, required this.child});

  final String pageId;
  final Widget child;

  @override
  State<TourAutoStart> createState() => _TourAutoStartState();
}

class _TourAutoStartState extends State<TourAutoStart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tours?.maybeStart(widget.pageId, context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// For a tab shell whose pages all stay mounted (IndexedStack): starts a tab's
/// tour when that tab is *selected* for the first time, and lets tour steps
/// switch tabs.
class TourTabAutoStart extends StatefulWidget {
  const TourTabAutoStart({
    super.key,
    required this.index,
    required this.tabs,
    required this.child,
  });

  /// The shell's selected-tab index.
  final RxInt index;

  /// Page id for each tab index.
  final List<String> tabs;

  final Widget child;

  @override
  State<TourTabAutoStart> createState() => _TourTabAutoStartState();
}

class _TourTabAutoStartState extends State<TourTabAutoStart> {
  Worker? _worker;

  Future<void> _navigate(String pageId) async {
    final i = widget.tabs.indexOf(pageId);
    if (i < 0) return;
    widget.index.value = i;
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  void initState() {
    super.initState();
    _tours?.setTabNavigator(_navigate);
    _worker = ever<int>(widget.index, _onTab);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTab(widget.index.value));
  }

  void _onTab(int i) {
    final service = _tours;
    if (!mounted || service == null || i < 0 || i >= widget.tabs.length) return;
    final pageId = widget.tabs[i];
    service.activeTab.value = pageId;
    if (service.running.value == null) service.maybeStart(pageId, context);
  }

  @override
  void dispose() {
    _worker?.dispose();
    _tours?.setTabNavigator(null);
    _tours?.activeTab.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
