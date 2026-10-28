import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'my_world_cluster_sheet.dart';
import 'my_world_controller.dart';
import 'my_world_globe.dart';
import 'my_world_models.dart';

/// "My World": the user's own activity as pillars on a night-time
/// globe. Opened from its tile on Home.
class MyWorldView extends StatefulWidget {
  const MyWorldView({super.key});

  static Future<void> open() async {
    if (!Get.isRegistered<MyWorldController>()) Get.put(MyWorldController());
    await Get.to(() => const MyWorldView());
    // Private data: dropped when the screen closes, fetched fresh next time.
    if (Get.isRegistered<MyWorldController>()) Get.delete<MyWorldController>();
  }

  @override
  State<MyWorldView> createState() => _MyWorldViewState();
}

class _MyWorldViewState extends State<MyWorldView> with SingleTickerProviderStateMixin {
  final controller = Get.find<MyWorldController>();
  final camera = GlobeCamera();

  /// Turning on its own; off by default when the platform asks for less motion.
  bool? _autoRotate;

  /// Where "reset" returns to: facing the biggest pillar once there is one.
  ({double yaw, double pitch}) _home = (yaw: 0, pitch: 0.3);
  bool _homed = false;

  late final AnimationController _reset = AnimationController(vsync: this, duration: AtharMotion.emphasis);
  Worker? _clustersWorker;

  @override
  void initState() {
    super.initState();
    _clustersWorker = ever<List<WorldCluster>>(controller.clusters, (list) {
      if (_homed || list.isEmpty) return;
      // Face the user's activity the first time it arrives.
      final top = list.first;
      _home = GlobeCamera.facing(top.lat, top.lng);
      _homed = true;
      _resetCamera();
    });
  }

  @override
  void dispose() {
    _clustersWorker?.dispose();
    _reset.dispose();
    camera.dispose();
    super.dispose();
  }

  void _resetCamera() {
    final from = (yaw: camera.yaw, pitch: camera.pitch, zoom: camera.zoom);
    // The short way round.
    var dyaw = (_home.yaw - from.yaw) % (2 * math.pi);
    if (dyaw > math.pi) dyaw -= 2 * math.pi;

    void apply(double t) {
      camera.set(
        yaw: from.yaw + dyaw * t,
        pitch: from.pitch + (_home.pitch - from.pitch) * t,
        zoom: from.zoom + (1 - from.zoom) * t,
      );
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      apply(1);
    } else {
      _reset
        ..stop()
        ..reset();
      final curve = CurvedAnimation(parent: _reset, curve: AtharMotion.emphasized);
      void listener() => apply(curve.value);
      _reset.addListener(listener);
      _reset.forward().whenCompleteOrCancel(() => _reset.removeListener(listener));
    }
    controller.onZoom(1);
  }

  void _zoomBy(double factor) {
    camera.set(zoom: camera.zoom * factor);
    controller.onZoom(camera.zoom);
  }

  void _openCluster(WorldCluster cluster) {
    showAtharSheet<void>(
      context: context,
      builder: (_) => MyWorldClusterSheet(cluster: cluster, categories: controller.selectedIds),
    );
  }

  void _openFilters() {
    showAtharSheet<void>(context: context, builder: (_) => const _FilterSheet());
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.athar.brand;
    final autoRotate = _autoRotate ??= !MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AtharAppBar(title: 'my_world_title'.tr, subtitle: 'my_world_subtitle'.tr),
      body: Stack(
        children: [
          // The globe isn't mirrored in RTL: east stays east.
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Obx(
                () => Semantics(
                  label: 'my_world_globe_semantics'.trParams({'count': '${controller.clusters.length}'}),
                  child: MyWorldGlobe(
                    camera: camera,
                    clusters: controller.clusters.toList(),
                    autoRotate: autoRotate,
                    atmosphere: accent,
                    onClusterTap: _openCluster,
                    onZoomChanged: controller.onZoom,
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: AtharSpace.sm,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AtharSpace.md),
                child: _Controls(
                  playing: autoRotate,
                  onPlayPause: () => setState(() => _autoRotate = !autoRotate),
                  onZoomIn: () => _zoomBy(1.4),
                  onZoomOut: () => _zoomBy(1 / 1.4),
                  onReset: _resetCamera,
                  onFilters: _openFilters,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: AtharSpace.sm,
            end: 72,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AtharSpace.md),
                child: _Status(onResetFilters: controller.resetFilters),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A panel over the globe in the app theme's card colours.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(AtharSpace.sm)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.athar.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AtharRadius.card),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: AtharTone.brand.foreground(context)),
        child: child,
      ),
    );
  }
}

/// Category filters, opened from the side bar: multi-select chips by the
/// server's ids, with select all and reset. The globe updates as they change.
class _FilterSheet extends GetView<MyWorldController> {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AtharSpace.screen, 0, AtharSpace.screen, AtharSpace.lg),
        child: Obx(() {
          final totals = controller.meta.value?.categoryTotals ?? const <String, int>{};
          final allOn = controller.selected.length == WorldCategory.all.length;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtharSheetHeader(title: 'my_world_filters_title'.tr),
              const SizedBox(height: AtharSpace.md),
              Wrap(
                spacing: AtharSpace.xs,
                runSpacing: AtharSpace.xs,
                children: [
                  for (final c in WorldCategory.all)
                    AtharChoiceChip(
                      icon: c.icon,
                      label: totals.containsKey(c.id) ? '${c.labelKey.tr} · ${totals[c.id]}' : c.labelKey.tr,
                      selected: controller.selected.contains(c.id),
                      onSelected: () => controller.toggleCategory(c.id),
                    ),
                ],
              ),
              const SizedBox(height: AtharSpace.md),
              Row(
                children: [
                  TextButton(onPressed: allOn ? null : controller.selectAll, child: Text('my_world_select_all'.tr)),
                  const SizedBox(width: AtharSpace.xs),
                  TextButton(onPressed: controller.resetFilters, child: Text('my_world_reset_filters'.tr)),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.onPlayPause,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onFilters,
  });

  final bool playing;
  final VoidCallback onPlayPause;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyWorldController>();
    Widget button(IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(icon: Icon(icon), tooltip: tooltip, color: AtharTone.brand.foreground(context), onPressed: onTap);

    return _Glass(
      padding: const EdgeInsets.all(AtharSpace.xxs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final filtered = controller.selected.length < WorldCategory.all.length;
            return IconButton(
              icon: Badge(
                isLabelVisible: filtered,
                smallSize: 8,
                backgroundColor: context.athar.gold,
                child: const Icon(Icons.tune_rounded),
              ),
              tooltip: 'my_world_filters_title'.tr,
              color: AtharTone.brand.foreground(context),
              onPressed: onFilters,
            );
          }),
          button(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            playing ? 'my_world_pause'.tr : 'my_world_play'.tr,
            onPlayPause,
          ),
          button(Icons.add_rounded, 'my_world_zoom_in'.tr, onZoomIn),
          button(Icons.remove_rounded, 'my_world_zoom_out'.tr, onZoomOut),
          button(Icons.center_focus_strong_rounded, 'my_world_reset_camera'.tr, onReset),
        ],
      ),
    );
  }
}

/// Bottom-left: the visible total and legend, or the state the screen is in
/// (loading, error, nothing to show and why).
class _Status extends GetView<MyWorldController> {
  const _Status({required this.onResetFilters});

  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meta = controller.meta.value;
      final error = controller.loadError.value;
      final loading = controller.loading.value;

      if (error != null) {
        return _Message(
          icon: Icons.cloud_off_rounded,
          title: error,
          action: TextButton(onPressed: controller.load, child: Text('my_world_retry'.tr)),
        );
      }
      if (meta == null) {
        return _Message(icon: Icons.public_rounded, title: 'my_world_loading'.tr, busy: true);
      }
      if (meta.totalRecords == 0) {
        return _Message(
          icon: Icons.public_rounded,
          title: 'my_world_empty_title'.tr,
          message: 'my_world_empty_message'.tr,
        );
      }
      if (controller.selected.isEmpty || meta.filteredRecords == 0) {
        return _Message(
          icon: Icons.filter_alt_off_rounded,
          title: 'my_world_no_match_title'.tr,
          action: TextButton(onPressed: onResetFilters, child: Text('my_world_reset_filters'.tr)),
        );
      }
      if (meta.visibleTotal == 0 && meta.unmapped > 0) {
        return _Message(
          icon: Icons.location_off_rounded,
          title: 'my_world_unmapped_title'.tr,
          message: 'my_world_unmapped_message'.trParams({'count': '${meta.unmapped}'}),
        );
      }

      return _Legend(meta: meta, busy: loading, categories: controller.selectedIds);
    });
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.message, this.action, this.busy = false});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: _Glass(
        padding: const EdgeInsets.all(AtharSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (busy)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AtharTone.brand.foreground(context)),
              )
            else
              Icon(icon, color: AtharTone.brand.foreground(context)),
            const SizedBox(width: AtharSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: context.type.bodyStrong),
                  if (message != null) ...[
                    const SizedBox(height: AtharSpace.xxs),
                    Text(message!, style: context.type.caption),
                  ],
                  if (action != null) Align(alignment: AlignmentDirectional.centerStart, child: action),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The visible total, records with no usable place, and what a pillar's
/// colours, height and faded look mean.
class _Legend extends StatelessWidget {
  const _Legend({required this.meta, required this.busy, required this.categories});

  final WorldMeta meta;
  final bool busy;

  /// Selected category ids.
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final caption = context.type.caption;
    return _Glass(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'my_world_visible_total'.trParams({'count': '${meta.visibleTotal}'}),
                  style: context.type.bodyStrong,
                ),
              ),
              if (busy) ...[
                const SizedBox(width: AtharSpace.xs),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AtharTone.brand.foreground(context)),
                ),
              ],
            ],
          ),
          if (meta.unmapped > 0) Text('my_world_unmapped_note'.trParams({'count': '${meta.unmapped}'}), style: caption),
          const SizedBox(height: AtharSpace.xs),
          // Which colour is which category, for the ones selected.
          Wrap(
            spacing: AtharSpace.sm,
            runSpacing: AtharSpace.xxs,
            children: [
              for (final c in WorldCategory.all)
                if (categories.contains(c.id))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Swatch(color: c.color),
                      const SizedBox(width: AtharSpace.xxs),
                      Text(c.labelKey.tr, style: caption),
                    ],
                  ),
            ],
          ),
          const SizedBox(height: AtharSpace.xxs),
          Text('my_world_legend_size'.tr, style: caption),
          Text('my_world_legend_tap'.tr, style: caption),
          Text('my_world_legend_approximate'.tr, style: caption),
        ],
      ),
    );
  }
}

/// A category's colour, as a small upright bar like a pillar segment.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 14,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}
