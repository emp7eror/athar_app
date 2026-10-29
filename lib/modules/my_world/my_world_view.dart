import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../../core/utils/snackbar.dart';
import 'my_world_cluster_sheet.dart';
import 'my_world_controller.dart';
import 'my_world_globe.dart';
import 'my_world_hotspots.dart';
import 'my_world_models.dart';
import 'my_world_share.dart';

/// "My World": the user's own activity as glowing hotspots on a night-time
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

  /// The globe's own layer, captured for sharing.
  final _globeKey = GlobalKey();
  bool _sharing = false;

  /// Turning on its own; off by default when the platform asks for less motion.
  bool? _autoRotate;

  /// Where "reset" returns to: facing the biggest hotspot once there is one.
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

  /// Turns the globe back to facing [_home] at world scale; completes once
  /// it is there.
  Future<void> _resetCamera() async {
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

    controller.onZoom(1);
    if (MediaQuery.disableAnimationsOf(context)) {
      apply(1);
      return;
    }
    _reset
      ..stop()
      ..reset();
    final curve = CurvedAnimation(parent: _reset, curve: AtharMotion.emphasized);
    void listener() => apply(curve.value);
    _reset.addListener(listener);
    await _reset.forward().orCancel.catchError((_) {});
    _reset.removeListener(listener);
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

  /// Shares the globe as a picture with the page's words. The globe first
  /// turns to centre the main glow (the busiest place) with the whole Earth
  /// in view, and holds still while it is captured.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    if (controller.clusters.isNotEmpty) {
      final top = controller.clusters.first;
      _home = GlobeCamera.facing(top.lat, top.lng);
    }
    await _resetCamera();
    // Drawn where it stopped before it is captured.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final box = _globeKey.currentContext?.size;
    final shared =
        box != null &&
        await MyWorldShare.share(
          globeKey: _globeKey,
          globeRadius: camera.radiusIn(box),
          glow: HotspotStyle.lit(context.athar.brand),
        );
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!shared) AppSnackbar.error('my_world_share'.tr, 'my_world_share_failed'.tr);
  }

  void _openFilters() {
    showAtharSheet<void>(context: context, builder: (_) => const _FilterSheet());
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.athar.brand;
    final autoRotate = _autoRotate ??= !MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons over the night sky.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        // No top bar: the globe fills the screen. The page's title is in the
        // card at the bottom; the Home tile keeps the short name.
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
                      autoRotate: autoRotate && !_sharing,
                      atmosphere: accent,
                      highlight: context.athar.gold,
                      onClusterTap: _openCluster,
                      onZoomChanged: controller.onZoom,
                      captureKey: _globeKey,
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
                  child: _Status(onResetFilters: controller.resetFilters, sharing: _sharing, onShare: _share),
                ),
              ),
            ),
            const PositionedDirectional(
              top: 0,
              start: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(padding: EdgeInsets.all(AtharSpace.sm), child: _BackButton()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back, floating over the globe in the panels' style: the only thing left
/// of the top bar.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.athar.card.withValues(alpha: 0.94),
      shape: CircleBorder(side: BorderSide(color: context.colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        // Points the right way in Arabic and English.
        icon: const BackButtonIcon(),
        color: AtharTone.brand.foreground(context),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
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

/// The card at the bottom: the page's title, then the visible total and
/// legend, or the state the screen is in (loading, error, nothing to show
/// and why).
class _Status extends GetView<MyWorldController> {
  const _Status({required this.onResetFilters, required this.sharing, required this.onShare});

  final VoidCallback onResetFilters;

  /// A picture is being made; the share button waits.
  final bool sharing;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.fromLTRB(AtharSpace.md, AtharSpace.md, AtharSpace.md, AtharSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(sharing: sharing, onShare: onShare),
          const SizedBox(height: AtharSpace.sm),
          _content(),
        ],
      ),
    );
  }

  Widget _content() {
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

      return _Legend(meta: meta, busy: loading);
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: AtharSpace.xxs),
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

/// The visible total, records with no usable place, and what a hotspot's
/// glow and dashed ring mean.
class _Legend extends StatelessWidget {
  const _Legend({required this.meta, required this.busy});

  final WorldMeta meta;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final caption = context.type.caption;
    return Column(
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
        Row(
          children: [
            const _GlowSample(),
            const SizedBox(width: AtharSpace.xs),
            Flexible(child: Text('my_world_legend_size'.tr, style: caption)),
          ],
        ),
        const SizedBox(height: AtharSpace.xxs),
        Text('my_world_legend_tap'.tr, style: caption),
        Text('my_world_legend_approximate'.tr, style: caption),
      ],
    );
  }
}

/// The page's title at the head of the bottom card: a gold sparkle, the
/// first line strong, the second in a soft gradient from the theme colour to
/// gold, and a fine gold rule beneath that fades out. Share sits at the end
/// of the first line.
class _Title extends StatelessWidget {
  const _Title({required this.sharing, required this.onShare});

  final bool sharing;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final brand = AtharTone.brand.foreground(context);
    final gold = context.athar.gold;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // From the reading start: theme colour, then gold.
    final gradient = LinearGradient(
      begin: AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
      end: AlignmentDirectional.centerEnd.resolve(Directionality.of(context)),
      colors: [brand, gold],
    );

    final share = IconButton(
      icon: sharing
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: brand))
          : const Icon(Icons.share_rounded, size: 20),
      tooltip: 'my_world_share'.tr,
      color: brand,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(backgroundColor: brand.withValues(alpha: 0.12)),
      onPressed: sharing ? null : onShare,
    );
    final title = [
      Icon(Icons.auto_awesome_rounded, size: 18, color: gold),
      const SizedBox(width: AtharSpace.xs),
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            'my_world_page_title'.tr,
            style: context.type.sectionTitle.copyWith(height: 1.3, letterSpacing: rtl ? 0 : 0.2),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          // Share at the end of the line: on the left in Arabic, the right
          // in English.
          children: [...title, const SizedBox(width: AtharSpace.xs), share],
        ),
        const SizedBox(height: AtharSpace.xxs),
        // Text in white, coloured by the gradient laid over it.
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: gradient.createShader,
          child: Text(
            'my_world_subtitle'.tr,
            style: context.type.bodyStrong.copyWith(
              fontSize: (context.type.bodyStrong.fontSize ?? 14) + 1,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: AtharSpace.sm),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradient.begin,
              end: gradient.end,
              colors: [gold.withValues(alpha: 0.7), gold.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Three glows from faint to strong on a patch of night, in the theme's
/// colour as on the globe, for the legend (which sits on the theme's card,
/// light or dark).
class _GlowSample extends StatelessWidget {
  const _GlowSample();

  @override
  Widget build(BuildContext context) {
    final glow = HotspotStyle.lit(context.athar.brand);
    Widget spot(double size, double strength) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(glow, Colors.white, 0.35 + 0.25 * strength),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.35 + 0.45 * strength),
            blurRadius: size * 2.2,
            spreadRadius: size * 0.3,
          ),
        ],
      ),
    );

    return Container(
      width: 64,
      height: 24,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(AtharRadius.sm)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [spot(3, 0), spot(4.5, 0.5), spot(6, 1)]),
    );
  }
}
