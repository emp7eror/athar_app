import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/ui/athar_ui.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';
import 'my_world_controller.dart';
import 'my_world_models.dart';

/// One hotspot's records, newest first, a page at a time as the list
/// scrolls. Same filters as the globe that opened it.
class MyWorldRecordsView extends StatefulWidget {
  const MyWorldRecordsView({super.key, required this.clusterId, required this.categories, required this.title});

  final String clusterId;
  final List<String> categories;
  final String title;

  @override
  State<MyWorldRecordsView> createState() => _MyWorldRecordsViewState();
}

class _MyWorldRecordsViewState extends State<MyWorldRecordsView> {
  final _records = <WorldRecord>[];
  final _scroll = ScrollController();

  int _page = 0;
  int _lastPage = 1;
  int _total = 0;
  bool _loading = false;
  String? _error;

  bool get _hasMore => _page < _lastPage;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _next();
    });
    _next();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_loading || (!_hasMore && _page > 0)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Get.find<ApiProvider>().myWorldClusterRecords(
        widget.clusterId,
        categories: widget.categories,
        page: _page + 1,
      );
      if (!mounted) return;
      final meta = Map<String, dynamic>.from(res['meta'] as Map? ?? const {});
      setState(() {
        _records.addAll([
          for (final r in (res['records'] as List? ?? const []))
            WorldRecord.fromJson(Map<String, dynamic>.from(r as Map)),
        ]);
        _page = (meta['current_page'] as num?)?.toInt() ?? _page + 1;
        _lastPage = (meta['last_page'] as num?)?.toInt() ?? _page;
        _total = (meta['total'] as num?)?.toInt() ?? _records.length;
      });
    } catch (e, st) {
      ErrorReporter.report(e, st);
      if (mounted) setState(() => _error = MyWorldController.messageFor(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_records.isEmpty && _loading) {
      body = AtharLoadingState(message: 'my_world_loading'.tr);
    } else if (_records.isEmpty && _error != null) {
      body = AtharErrorState(message: _error!, onRetry: _next);
    } else if (_records.isEmpty) {
      body = AtharEmptyState(icon: Icons.inbox_rounded, title: 'my_world_records_empty'.tr);
    } else {
      body = ListView.separated(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          AtharSpace.screen,
          AtharSpace.md,
          AtharSpace.screen,
          AtharSpace.xl + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: _records.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AtharSpace.xs),
        itemBuilder: (context, i) {
          if (i == _records.length) return _footer();
          return _RecordTile(record: _records[i]);
        },
      );
    }

    return Scaffold(
      appBar: AtharAppBar(
        title: widget.title,
        subtitle: _total > 0 ? 'my_world_cluster_total'.trParams({'count': '$_total'}) : null,
      ),
      body: body,
    );
  }

  Widget _footer() {
    if (_error != null) {
      return Center(
        child: TextButton(onPressed: _next, child: Text('my_world_retry'.tr)),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AtharSpace.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final WorldRecord record;

  String _title() {
    final category = WorldCategory.byId(record.category);
    final label = category?.labelKey.tr ?? record.category;
    switch (record.category) {
      case 'prayer':
        return record.detail == null ? label : '$label · ${record.detail!.tr}';
      case 'tasbih':
      case 'istighfar':
        return '$label · ${'my_world_times'.trParams({'count': '${record.amount ?? 0}'})}';
      case 'quran':
        return record.detail == null ? label : '$label · ${'my_world_page'.trParams({'page': record.detail!})}';
      case 'sadaqah':
        return record.detail == null ? label : '$label · ${record.detail}';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final category = WorldCategory.byId(record.category);
    final locale = Get.locale?.toLanguageTag();
    final day = DateFormat.yMMMEd(locale).format(record.day);
    final time = record.occurredAt == null ? null : DateFormat.jm(locale).format(record.occurredAt!);

    return AtharCard(
      child: Row(
        children: [
          Icon(category?.icon ?? Icons.circle, color: AtharTone.brand.foreground(context)),
          const SizedBox(width: AtharSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title(), style: context.type.bodyStrong),
                Text(time == null ? day : '$day · $time', style: context.type.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
