import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import 'my_world_controller.dart';
import 'my_world_models.dart';
import 'my_world_records_view.dart';

/// A tapped hotspot: where it is, how many records, which kinds, and whether
/// the place is only approximate. Details come from the server for the same
/// filters the globe is showing.
class MyWorldClusterSheet extends StatefulWidget {
  const MyWorldClusterSheet({super.key, required this.cluster, required this.categories});

  final WorldCluster cluster;
  final List<String> categories;

  @override
  State<MyWorldClusterSheet> createState() => _MyWorldClusterSheetState();
}

class _MyWorldClusterSheetState extends State<MyWorldClusterSheet> {
  WorldClusterDetails? _details;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await Get.find<ApiProvider>().myWorldCluster(widget.cluster.id, categories: widget.categories);
      if (!mounted) return;
      setState(() => _details = WorldClusterDetails.fromJson(Map<String, dynamic>.from(res['cluster'] as Map)));
    } catch (e, st) {
      ErrorReporter.report(e, st);
      if (mounted) setState(() => _error = MyWorldController.messageFor(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _details;
    // Until the details land, the hotspot's own numbers stand in.
    final total = d?.total ?? widget.cluster.total;
    final counts = d?.counts ?? widget.cluster.counts;
    final approximate = d?.approximate ?? widget.cluster.approximate;

    final place = d == null
        ? null
        : [if (d.city != null) d.city!, if (d.country != null) d.country!].join('my_world_place_separator'.tr);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AtharSpace.screen, 0, AtharSpace.screen, AtharSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AtharSheetHeader(
              title: place == null || place.isEmpty ? 'my_world_area_unknown'.tr : place,
              subtitle: 'my_world_cluster_total'.trParams({'count': '$total'}),
            ),
            if (approximate) ...[
              const SizedBox(height: AtharSpace.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AtharBadge(
                  icon: Icons.blur_on_rounded,
                  label: 'my_world_approximate'.tr,
                  tone: AtharTone.warning,
                ),
              ),
              const SizedBox(height: AtharSpace.xxs),
              Text('my_world_approximate_hint'.tr, style: context.type.caption),
            ],
            if (_error != null) ...[
              const SizedBox(height: AtharSpace.sm),
              AtharErrorState(message: _error!, onRetry: _load),
            ],
            const SizedBox(height: AtharSpace.md),
            for (final c in WorldCategory.all)
              if (counts.containsKey(c.id)) _BreakdownRow(category: c, count: counts[c.id] ?? 0, total: total),
            const SizedBox(height: AtharSpace.md),
            AtharButton(
              label: 'my_world_view_records'.tr,
              icon: Icons.list_alt_rounded,
              expand: true,
              onPressed: total == 0
                  ? null
                  : () => Get.to(
                      () => MyWorldRecordsView(
                        clusterId: widget.cluster.id,
                        categories: widget.categories,
                        title: place == null || place.isEmpty ? 'my_world_records_title'.tr : place,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.category, required this.count, required this.total});

  final WorldCategory category;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final accent = AtharTone.brand.foreground(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AtharSpace.xxs),
      child: Semantics(
        label: '${category.labelKey.tr}: $count',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(category.icon, size: AtharSize.icon, color: accent),
            const SizedBox(width: AtharSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(category.labelKey.tr, style: context.type.body)),
                      Text('$count', style: context.type.bodyStrong),
                    ],
                  ),
                  const SizedBox(height: AtharSpace.xxs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AtharRadius.pill),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : count / total,
                      minHeight: 4,
                      color: accent,
                      backgroundColor: context.colors.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
