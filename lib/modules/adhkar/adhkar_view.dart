import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'adhkar_collection_view.dart';
import 'adhkar_editors.dart';
import 'adhkar_icons.dart';
import 'adhkar_models.dart';
import 'adhkar_reminders.dart';
import 'adhkar_store.dart';

/// Adhkar & Duas — a separate feature from the tasbeeh counters.
///
/// Both tabs work the same way: the reader's own collections on top, where
/// they count, and the public categories below, which are read-only and can be
/// copied into the reader's collections. Content is cached for offline
/// reading; counting works offline and syncs later.
class AdhkarView extends StatefulWidget {
  const AdhkarView({super.key});

  /// Registers the store and reminders once, then opens the page.
  static Future<void> open() async {
    ensureServices();
    await Get.to(() => const AdhkarView());
  }

  static void ensureServices() {
    if (!Get.isRegistered<AdhkarStore>()) {
      Get.put(AdhkarStore(), permanent: true);
    }
    if (!Get.isRegistered<AdhkarReminders>()) {
      Get.put(AdhkarReminders(), permanent: true);
    }
  }

  @override
  State<AdhkarView> createState() => _AdhkarViewState();
}

class _AdhkarViewState extends State<AdhkarView> {
  late final AdhkarStore _store;
  final _searchField = TextEditingController();

  /// The search, shared by both tabs. Searching replaces the title.
  final _query = ''.obs;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    AdhkarView.ensureServices();
    _store = Get.find<AdhkarStore>();
    unawaited(_store.loadContent());
  }

  @override
  void dispose() {
    _searchField.dispose();
    super.dispose();
  }

  void _closeSearch() {
    setState(() => _searching = false);
    _searchField.clear();
    _query.value = '';
  }

  PreferredSizeWidget _tabs() => TabBar(
    tabs: [
      Tab(text: 'adhkar_tab_adhkar'.tr),
      Tab(text: 'adhkar_tab_duas'.tr),
    ],
  );

  PreferredSizeWidget _appBar(BuildContext context) {
    if (!_searching) {
      return AtharAppBar(
        title: 'adhkar_title'.tr,
        actions: [
          AtharIconButton(
            icon: Icons.search_rounded,
            tooltip: 'adhkar_search'.tr,
            onPressed: () => setState(() => _searching = true),
          ),
          AtharIconButton(
            icon: Icons.notifications_active_rounded,
            tooltip: 'adhkar_reminders'.tr,
            onPressed: () => AdhkarRemindersSheet.show(context),
          ),
        ],
        bottom: _tabs(),
      );
    }
    return AppBar(
      toolbarHeight: 60,
      leading: AtharIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'adhkar_close_search'.tr,
        onPressed: _closeSearch,
      ),
      titleSpacing: 0,
      title: TextField(
        controller: _searchField,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: (v) => _query.value = v,
        decoration: InputDecoration(
          hintText: 'adhkar_search_hint'.tr,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
      actions: [
        Obx(
          () => _query.value.isEmpty
              ? const SizedBox.shrink()
              : AtharIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'adhkar_clear_search'.tr,
                  onPressed: () {
                    _searchField.clear();
                    _query.value = '';
                  },
                ),
        ),
      ],
      bottom: _tabs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PopScope(
        // Back closes the search first.
        canPop: !_searching,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _searching) _closeSearch();
        },
        child: Scaffold(
          appBar: _appBar(context),
          body: Obx(() {
            if (!_store.contentReady.value) {
              final error = _store.contentError.value;
              if (error != null && !_store.loadingContent.value) {
                return AtharErrorState(
                  message: error,
                  onRetry: _store.loadContent,
                );
              }
              return const AtharLoadingState();
            }
            return Column(
              children: [
                if (_store.offline.value) const _OfflineBanner(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _Tab(type: AdhkarType.adhkar, query: _query),
                      _Tab(type: AdhkarType.dua, query: _query),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.athar.warning.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(
        horizontal: AtharSpace.screen,
        vertical: AtharSpace.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: AtharSize.iconSm,
            color: context.athar.warning,
          ),
          const SizedBox(width: AtharSpace.xs),
          Expanded(
            child: Text(
              'adhkar_offline_banner'.tr,
              style: context.type.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tab: the reader's own collections, then the public categories — or,
/// while searching, the results.
class _Tab extends StatefulWidget {
  const _Tab({required this.type, required this.query});

  final AdhkarType type;
  final RxString query;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with AutomaticKeepAliveClientMixin {
  final _store = Get.find<AdhkarStore>();

  bool get _isDua => widget.type == AdhkarType.dua;

  @override
  bool get wantKeepAlive => true;

  List<AdhkarCollection> _mine() =>
      _store.mine.where((c) => c.type == widget.type).toList();

  List<AdhkarCollection> _categories() =>
      _isDua ? _store.categories.toList() : _store.publicCollections.toList();

  Future<void> _newCollection() async {
    final created = await AdhkarCollectionEditor.show(
      context,
      type: widget.type,
    );
    if (created != null) unawaited(AdhkarCollectionView.open(created));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      _store.revision.value;
      final mine = _mine();
      final categories = _categories();
      final q = AdhkarSearch.normalize(widget.query.value);

      return RefreshIndicator(
        onRefresh: _store.loadContent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AtharSpace.screen,
            AtharSpace.md,
            AtharSpace.screen,
            AtharSpace.xxl,
          ),
          children: q.isNotEmpty
              ? _results(context, [...mine, ...categories], q)
              : _sections(context, mine, categories),
        ),
      );
    });
  }

  List<Widget> _sections(
    BuildContext context,
    List<AdhkarCollection> mine,
    List<AdhkarCollection> categories,
  ) {
    return [
      AtharSectionHeader(
        title: _isDua ? 'adhkar_my_duas'.tr : 'adhkar_my_adhkar'.tr,
        actionLabel: 'adhkar_new_collection'.tr,
        onAction: _newCollection,
      ),
      if (mine.isEmpty)
        AtharCard(
          tone: AtharCardTone.surface,
          child: Text(
            _isDua
                ? 'adhkar_my_duas_empty'.tr
                : 'adhkar_my_collections_empty'.tr,
            style: context.type.caption,
          ),
        )
      else
        for (final c in mine) _CollectionTile(collection: c),
      const SizedBox(height: AtharSpace.lg),
      AtharSectionHeader(
        title: _isDua ? 'adhkar_dua_categories'.tr : 'adhkar_categories'.tr,
      ),
      if (categories.isEmpty)
        AtharEmptyState(
          icon: Icons.auto_stories_rounded,
          title: 'adhkar_no_categories'.tr,
        )
      else
        for (final c in categories) _CollectionTile(collection: c),
    ];
  }

  /// Items whose text (or occasion / source / virtue / notes) matches, from
  /// the reader's own collections and the public categories — nothing else is
  /// on the device.
  List<Widget> _results(
    BuildContext context,
    List<AdhkarCollection> collections,
    String q,
  ) {
    final hits = <(AdhkarCollection, AdhkarItem)>[];
    for (final c in collections) {
      final nameHit = AdhkarSearch.matches(c.name, q);
      for (final item in c.items) {
        final text = [
          item.occasionAr ?? '',
          item.occasionEn ?? '',
          item.text,
          item.reference ?? '',
          item.virtue ?? '',
          item.notes ?? '',
        ].join(' ');
        if (nameHit || AdhkarSearch.matches(text, q)) hits.add((c, item));
      }
      if (hits.length >= 200) break;
    }

    if (hits.isEmpty) {
      return [
        AtharEmptyState(
          icon: Icons.search_off_rounded,
          title: 'adhkar_search_empty'.tr,
          message: 'adhkar_search_empty_sub'.tr,
        ),
      ];
    }
    return [
      Text(
        'adhkar_search_count'.trParams({'n': '${hits.length}'}),
        style: context.type.caption,
      ),
      const SizedBox(height: AtharSpace.xs),
      for (final (c, item) in hits)
        Padding(
          padding: const EdgeInsets.only(bottom: AtharSpace.xs),
          child: AtharCard(
            onTap: () => AdhkarCollectionView.open(c, focusKey: item.key),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.occasion != null) ...[
                  Text(
                    item.occasion!,
                    style: context.type.cardTitle.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: AtharSpace.xxs),
                ],
                Text(
                  item.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge?.copyWith(height: 1.8),
                ),
                const SizedBox(height: AtharSpace.xxs),
                Text(
                  c.isPersonal ? '${c.name} · ${'adhkar_mine'.tr}' : c.name,
                  style: context.type.caption,
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

/// A collection in a list. The reader's own show today's progress; public
/// categories, which aren't counted, show how many items they hold.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection});

  final AdhkarCollection collection;

  IconData get _icon => adhkarIconFor(collection);

  @override
  Widget build(BuildContext context) {
    final store = Get.find<AdhkarStore>();
    final scheme = context.colors;
    final targeted = collection.items.where((i) => i.hasTarget).toList();
    final done = collection.isPersonal
        ? targeted.where((i) => store.count(i.key) >= i.target!).length
        : 0;
    final allDone = targeted.isNotEmpty && done == targeted.length;

    final leading = collection.isPersonal
        ? AtharProgressRing(
            value: targeted.isEmpty ? 0 : done / targeted.length,
            size: 44,
            color: allDone ? context.athar.success : null,
            child: Icon(
              allDone ? Icons.check_rounded : _icon,
              size: AtharSize.icon,
              color: allDone ? context.athar.success : scheme.primary,
            ),
          )
        : Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AtharRadius.md),
            ),
            child: Icon(
              _icon,
              size: AtharSize.icon,
              color: scheme.onPrimaryContainer,
            ),
          );

    final subtitle = collection.isPersonal && targeted.isNotEmpty
        ? 'adhkar_progress_of'.trParams({
            'done': '$done',
            'total': '${targeted.length}',
          })
        : adhkarCountLabel(collection.type, collection.items.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: AtharSpace.xs),
      child: AtharCard(
        onTap: () => AdhkarCollectionView.open(collection),
        padding: const EdgeInsets.all(AtharSpace.sm),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AtharSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: context.type.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.type.caption),
                ],
              ),
            ),
            Icon(
              // Mirrors itself in Arabic.
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
