import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../../core/tour/tour_widgets.dart';
import '../tour/app_tours.dart';
import 'adhkar_card.dart';
import 'adhkar_editors.dart';
import 'adhkar_icons.dart';
import 'adhkar_models.dart';
import 'adhkar_reminders.dart';
import 'adhkar_session.dart';
import 'adhkar_share.dart';
import 'adhkar_store.dart';
import 'adhkar_sync_badge.dart';

/// Reading a collection — public or the reader's own — as a list of cards or
/// one item at a time. Both modes share one [AdhkarSession], so they count
/// and progress identically.
class AdhkarCollectionView extends StatefulWidget {
  const AdhkarCollectionView({
    super.key,
    required this.collection,
    this.focusKey,
  });

  final AdhkarCollection collection;

  /// An item to scroll to on opening (from a search result).
  final String? focusKey;

  static Future<void> open(
    AdhkarCollection collection, {
    String? focusKey,
  }) async {
    await Get.to(
      () => AdhkarCollectionView(collection: collection, focusKey: focusKey),
      preventDuplicates: false,
    );
  }

  @override
  State<AdhkarCollectionView> createState() => _AdhkarCollectionViewState();
}

class _AdhkarCollectionViewState extends State<AdhkarCollectionView> {
  late final AdhkarSession _session;
  final _store = Get.find<AdhkarStore>();
  final _scroll = ScrollController();
  final _pages = PageController();
  final _itemKeys = <String, GlobalKey>{};
  final _busy = false.obs;
  Worker? _advanceWorker;

  /// Items as shown, so a drag can reorder at once while it saves.
  List<AdhkarItem>? _optimisticOrder;

  /// Public categories: the items chosen to copy, by key. None chosen means
  /// the button copies the whole category.
  final _selected = <String>{};

  void _toggle(AdhkarItem item, bool on) =>
      setState(() => on ? _selected.add(item.key) : _selected.remove(item.key));

  /// The chosen items in their category order, or every item when none is
  /// chosen (copying the whole category).
  Future<void> _copy() async {
    final collection = _session.collection;
    if (_selected.isEmpty) {
      await _onMenu('copy');
      return;
    }
    final items = _items.where((i) => _selected.contains(i.key)).toList();
    final saved = await AdhkarCopyToSheet.show(
      context,
      items: items,
      type: collection.type,
    );
    if (saved && mounted) setState(_selected.clear);
  }

  @override
  void initState() {
    super.initState();
    _session = Get.put(
      AdhkarSession(widget.collection.uid, widget.collection),
      tag: '${widget.collection.uid}-${identityHashCode(this)}',
    );
    _advanceWorker = ever(_session.advance, (e) {
      if (e != null) _goTo(e.index);
    });
    unawaited(_store.refreshProgress());

    final focus = widget.focusKey;
    if (focus != null) {
      final i = _session.items.indexWhere((it) => it.key == focus);
      if (i >= 0) {
        _session.focus(i);
        WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(i));
      }
    }
  }

  @override
  void dispose() {
    _advanceWorker?.dispose();
    Get.delete<AdhkarSession>(
      tag: '${widget.collection.uid}-${identityHashCode(this)}',
    );
    _scroll.dispose();
    _pages.dispose();
    unawaited(_store.sync());
    super.dispose();
  }

  List<AdhkarItem> get _items => _optimisticOrder ?? _session.items;

  GlobalKey _keyFor(AdhkarItem item) =>
      _itemKeys.putIfAbsent(item.key, GlobalKey.new);

  /// Scrolls (list) or pages (one at a time) to [index].
  void _goTo(int index) {
    if (_session.sequential.value) {
      if (_pages.hasClients) {
        _pages.animateToPage(
          index,
          duration: AtharMotion.slow,
          curve: AtharMotion.standard,
        );
      }
      return;
    }
    final items = _items;
    if (index < 0 || index >= items.length) return;
    final ctx = _keyFor(items[index]).currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: AtharMotion.slow,
        curve: AtharMotion.standard,
        alignment: 0.15,
      );
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────

  Set<AdhkarCardAction> _actionsFor(AdhkarItem item, int index, int count) {
    // The reader's own collections only; public items are chosen instead.
    return {
      AdhkarCardAction.edit,
      if (index > 0) AdhkarCardAction.moveUp,
      if (index < _items.length - 1) AdhkarCardAction.moveDown,
      AdhkarCardAction.delete,
      AdhkarCardAction.share,
      if (count > 0) AdhkarCardAction.reset,
    };
  }

  String _snippet(AdhkarItem item) {
    final t = item.text.replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= 60 ? t : '${t.substring(0, 60)}…';
  }

  Future<void> _onAction(
    AdhkarItem item,
    int index,
    AdhkarCardAction action,
  ) async {
    final collection = _session.collection;
    switch (action) {
      case AdhkarCardAction.edit:
        await AdhkarItemEditor.show(
          context,
          collection: collection,
          existing: item,
        );
      case AdhkarCardAction.delete:
        final ok = await showAtharConfirm(
          title: adhkarWord('adhkar_delete_q', collection.type),
          message: _snippet(item),
          confirmLabel: 'adhkar_delete'.tr,
          icon: Icons.delete_outline_rounded,
          destructive: true,
        );
        if (ok) {
          await runAdhkarAction(
            _busy,
            () => _store.deleteItem(item),
            success: adhkarWord('adhkar_deleted', collection.type),
          );
        }
      case AdhkarCardAction.moveUp:
        await _move(index, index - 1);
      case AdhkarCardAction.moveDown:
        await _move(index, index + 1);
      case AdhkarCardAction.share:
        await shareAdhkarItem(context, item, collection);
      case AdhkarCardAction.reset:
        final ok = await showAtharConfirm(
          title: adhkarWord('adhkar_reset_q', collection.type),
          message: adhkarWord('adhkar_reset_msg', collection.type, {
            'text': _snippet(item),
          }),
          confirmLabel: 'adhkar_reset'.tr,
          icon: Icons.restart_alt_rounded,
        );
        if (ok) _session.resetItem(item);
    }
    if (mounted) setState(() {});
  }

  /// Moves an item and saves the new order. Shown at once; put back if the
  /// server doesn't take it.
  Future<void> _move(int from, int to) async {
    final items = [..._items];
    if (from < 0 ||
        from >= items.length ||
        to < 0 ||
        to >= items.length ||
        from == to) {
      return;
    }
    items.insert(to, items.removeAt(from));
    setState(() => _optimisticOrder = items);
    // On failure the error is shown and the saved order comes back.
    await runAdhkarAction(
      _busy,
      () =>
          _store.reorder(_session.collection, items.map((i) => i.id).toList()),
    );
    if (mounted) setState(() => _optimisticOrder = null);
  }

  Future<void> _resetAll() async {
    final ok = await showAtharConfirm(
      title: 'adhkar_reset_all_q'.tr,
      message: 'adhkar_reset_all_msg'.trParams({
        'name': _session.collection.name,
      }),
      confirmLabel: 'adhkar_reset_all'.tr,
      icon: Icons.restart_alt_rounded,
      destructive: true,
    );
    if (ok) _session.resetAll();
  }

  Future<void> _onMenu(String value) async {
    final collection = _session.collection;
    switch (value) {
      case 'add':
        await AdhkarItemEditor.show(context, collection: collection);
      case 'edit':
        await AdhkarCollectionEditor.show(
          context,
          type: collection.type,
          existing: collection,
        );
      case 'copy':
        final copy = await runAdhkarAction(
          _busy,
          () => _store.copyCollection(collection),
          success: 'adhkar_collection_copied'.tr,
        );
        if (copy != null) {
          Get.off(
            () => AdhkarCollectionView(collection: copy),
            preventDuplicates: false,
          );
        }
      case 'reset':
        await _resetAll();
      case 'delete':
        final ok = await showAtharConfirm(
          title: 'adhkar_delete_collection_q'.tr,
          message: 'adhkar_delete_collection_msg'.trParams({
            'name': collection.name,
          }),
          confirmLabel: 'adhkar_delete'.tr,
          icon: Icons.delete_outline_rounded,
          destructive: true,
        );
        if (!ok) return;
        final done = await runAdhkarAction(_busy, () async {
          await _store.deleteCollection(collection);
          // Its reminders would open a collection that is gone.
          await Get.find<AdhkarReminders>().removeForCollection(collection);
          return true;
        }, success: 'adhkar_collection_deleted'.tr);
        if (done == true) Get.back();
    }
    if (mounted) setState(() {});
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _store.revision.value; // counts
      _store.mine.length; // edits to the collection
      // Read here: list items are built lazily, outside this Obx's tracking.
      _session.current.value;
      final collection = _session.collection;
      // One at a time is for reading and counting the reader's own.
      final sequential = collection.isPersonal && _session.sequential.value;

      final page = Scaffold(
        appBar: AtharAppBar(
          title: collection.name,
          subtitle: collection.isPersonal ? 'adhkar_mine'.tr : null,
          actions: [
            // The reader's own collections only: their reminders, whose
            // notification opens them.
            if (collection.isPersonal)
              TourTarget(
                id: TourTargets.adhkarCollectionReminders,
                child: Obx(() {
                  final reminders = Get.find<AdhkarReminders>();
                  reminders.reminders.length;
                  final has = reminders
                      .forCollection(collection)
                      .any((r) => r.enabled);
                  return AtharIconButton(
                    icon: has
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    tooltip: 'adhkar_reminders'.tr,
                    onPressed: () => AdhkarRemindersSheet.show(
                      context,
                      collection: collection,
                    ),
                  );
                }),
              ),
            if (collection.isPersonal && _items.isNotEmpty)
              TourTarget(
                id: TourTargets.adhkarView,
                child: AtharIconButton(
                  icon: sequential
                      ? Icons.view_agenda_rounded
                      : Icons.view_carousel_rounded,
                  tooltip: sequential
                      ? 'adhkar_mode_list'.tr
                      : 'adhkar_mode_sequential'.tr,
                  onPressed: () {
                    _session.sequential.value = !sequential;
                    // Open the other view on the item being read.
                    final at = _session.current.value;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (at < 0) return;
                      if (_session.sequential.value) {
                        if (_pages.hasClients) _pages.jumpToPage(at);
                      } else {
                        _goTo(at);
                      }
                    });
                  },
                ),
              ),
            if (collection.isPersonal)
              TourTarget(
                id: TourTargets.adhkarMenu,
                child: PopupMenuButton<String>(
                  tooltip: 'adhkar_more'.tr,
                  onSelected: _onMenu,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'add',
                      child: Text(adhkarWord('adhkar_new', collection.type)),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('adhkar_edit_collection'.tr),
                    ),
                    if (_session.completed > 0 ||
                        _items.any((i) => _session.countOf(i) > 0))
                      PopupMenuItem(
                        value: 'reset',
                        child: Text('adhkar_reset_all'.tr),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'adhkar_delete_collection'.tr,
                        style: TextStyle(color: context.colors.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        // A public category: copy it, since it is only counted once it is the
        // reader's own. (The reader's own add items from the top menu.) Copy
        // sits on the right in both languages — end-side would put it on the
        // left in Arabic.
        floatingActionButtonLocation:
            Directionality.of(context) == TextDirection.rtl
            ? FloatingActionButtonLocation.startFloat
            : FloatingActionButtonLocation.endFloat,
        floatingActionButton: collection.isPersonal || _items.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: _busy.value ? null : _copy,
                icon: const Icon(Icons.library_add_rounded),
                // «نسخ الكل» with nothing chosen; otherwise how many.
                label: Text(adhkarCopyLabel(collection.type, _selected.length)),
              ),
        body: Stack(
          children: [
            Column(
              children: [
                if (collection.isPersonal)
                  _ProgressHeader(session: _session)
                else if (_items.isNotEmpty)
                  const _ReadOnlyHint(),
                Expanded(
                  child: _items.isEmpty
                      ? _empty(collection)
                      : sequential
                      ? _sequential()
                      : _list(collection),
                ),
              ],
            ),
            if (_busy.value)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black12,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
      // The tour of counting, reminders and the menu: the reader's own only.
      return collection.isPersonal
          ? TourAutoStart(pageId: TourPages.adhkarCollection, child: page)
          : page;
    });
  }

  Widget _empty(AdhkarCollection collection) => AtharEmptyState(
    icon: collection.type == AdhkarType.dua
        ? Icons.volunteer_activism_rounded
        : Icons.auto_awesome_rounded,
    title: 'adhkar_collection_empty'.tr,
    message: collection.isPersonal
        ? adhkarWord('adhkar_empty_mine', collection.type)
        : 'adhkar_collection_empty_public'.tr,
  );

  /// One item at a time, with previous / next. Same counters as the list.
  Widget _sequential() {
    final items = _items;
    final start = _session.current.value < 0 ? 0 : _session.current.value;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: items.length,
            onPageChanged: _session.focus,
            itemBuilder: (_, i) => SingleChildScrollView(
              padding: const EdgeInsets.all(AtharSpace.screen),
              child: _cardFor(items[i], i, large: true),
            ),
          ),
        ),
        _PagerBar(
          controller: _pages,
          count: items.length,
          initial: start,
          allDone: _session.allDone,
          onReset: _resetAll,
        ),
      ],
    );
  }

  Widget _cardFor(
    AdhkarItem item,
    int index, {
    Widget? dragHandle,
    bool large = false,
  }) {
    // Public categories are read here, not counted.
    final counting = _session.collection.isPersonal;
    final count = counting ? _session.countOf(item) : 0;
    final card = AdhkarCard(
      // The list scrolls to cards by key; a page needs none.
      key: large ? null : _keyFor(item),
      large: large,
      item: item,
      index: index,
      count: count,
      isCurrent: counting && _session.current.value == index,
      dragHandle: dragHandle,
      onCount: counting ? () => _session.increment(item) : null,
      // Public items have no menu: they are chosen for copying.
      actions: counting ? _actionsFor(item, index, count) : const {},
      onAction: counting ? (a) => _onAction(item, index, a) : null,
      selected: _selected.contains(item.key),
      onSelect: counting ? null : (on) => _toggle(item, on),
    );
    // The tour shows counting on the first card of the list.
    return counting && index == 0 && !large
        ? TourTarget(id: TourTargets.adhkarCount, child: card)
        : card;
  }

  Widget _list(AdhkarCollection collection) {
    final items = _items;
    const padding = EdgeInsets.fromLTRB(
      AtharSpace.screen,
      AtharSpace.xs,
      AtharSpace.screen,
      96,
    );

    if (!collection.isPersonal) {
      return ListView.separated(
        controller: _scroll,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AtharSpace.sm),
        itemBuilder: (_, i) => _cardFor(items[i], i),
      );
    }

    // The reader's own: drag the handle to reorder (works the same in RTL),
    // or use Move up / Move down from the card's menu.
    return ReorderableListView.builder(
      scrollController: _scroll,
      padding: padding,
      buildDefaultDragHandles: false,
      itemCount: items.length,
      footer: _session.allDone
          ? _DoneBanner(onReset: _resetAll, type: collection.type)
          : null,
      onReorderItem: _move,
      itemBuilder: (_, i) => Padding(
        key: ValueKey(items[i].key),
        padding: const EdgeInsets.only(bottom: AtharSpace.sm),
        child: _cardFor(
          items[i],
          i,
          dragHandle: ReorderableDragStartListener(
            index: i,
            child: Tooltip(
              message: 'adhkar_drag_to_reorder'.tr,
              child: const Padding(
                padding: EdgeInsetsDirectional.only(end: AtharSpace.xs),
                child: Icon(Icons.drag_indicator_rounded),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Collection progress and the sync state of the counters.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.session});

  final AdhkarSession session;

  @override
  Widget build(BuildContext context) {
    final targeted = session.targeted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AtharSpace.screen,
        AtharSpace.xs,
        AtharSpace.screen,
        AtharSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  targeted == 0
                      ? adhkarCountLabel(
                          session.collection.type,
                          session.items.length,
                        )
                      : 'adhkar_progress_of'.trParams({
                          'done': '${session.completed}',
                          'total': '$targeted',
                        }),
                  style: context.type.caption,
                ),
              ),
              const AdhkarSyncBadge(),
            ],
          ),
          if (targeted > 0) ...[
            const SizedBox(height: AtharSpace.xs),
            AtharProgressBar(
              value: session.progress,
              color: session.allDone ? context.athar.success : null,
              semanticsLabel: 'adhkar_progress'.tr,
              semanticsValue: '${session.completed} / $targeted',
            ),
          ],
        ],
      ),
    );
  }
}

/// Over a public category: it is for reading; counting happens in a copy.
class _ReadOnlyHint extends StatelessWidget {
  const _ReadOnlyHint();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AtharSpace.screen,
        AtharSpace.xs,
        AtharSpace.screen,
        AtharSpace.xs,
      ),
      padding: const EdgeInsets.all(AtharSpace.sm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AtharRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AtharSize.icon,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: AtharSpace.xs),
          Expanded(
            child: Text(
              'adhkar_public_hint'.tr,
              style: context.text.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneBanner extends StatelessWidget {
  const _DoneBanner({required this.onReset, required this.type});

  final VoidCallback onReset;
  final AdhkarType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AtharSpace.sm),
      child: AtharCard(
        tone: AtharCardTone.surface,
        child: Column(
          children: [
            Icon(
              Icons.verified_rounded,
              size: 40,
              color: context.athar.success,
            ),
            const SizedBox(height: AtharSpace.xs),
            Text(
              'adhkar_all_done'.tr,
              style: context.type.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AtharSpace.xxs),
            Text(
              adhkarWord('adhkar_all_done_sub', type),
              style: context.type.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AtharSpace.sm),
            AtharButton(
              label: 'adhkar_reset_all'.tr,
              variant: AtharButtonVariant.secondary,
              compact: true,
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

/// Previous / next and where the reader is, under the one-at-a-time view.
class _PagerBar extends StatefulWidget {
  const _PagerBar({
    required this.controller,
    required this.count,
    required this.initial,
    required this.allDone,
    required this.onReset,
  });

  final PageController controller;
  final int count;
  final int initial;
  final bool allDone;
  final VoidCallback onReset;

  @override
  State<_PagerBar> createState() => _PagerBarState();
}

class _PagerBarState extends State<_PagerBar> {
  late int _page = widget.initial;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    // Open on the item being read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.hasClients && widget.initial > 0) {
        widget.controller.jumpToPage(widget.initial);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final p = widget.controller.page?.round() ?? _page;
    if (p != _page && mounted) setState(() => _page = p);
  }

  void _to(int page) => widget.controller.animateToPage(
    page,
    duration: AtharMotion.base,
    curve: AtharMotion.standard,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AtharSpace.screen,
          0,
          AtharSpace.screen,
          AtharSpace.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allDone)
              Padding(
                padding: const EdgeInsets.only(bottom: AtharSpace.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: context.athar.success,
                      size: AtharSize.icon,
                    ),
                    const SizedBox(width: AtharSpace.xs),
                    Flexible(
                      child: Text(
                        'adhkar_all_done'.tr,
                        style: context.type.bodyStrong,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onReset,
                      child: Text('adhkar_reset_all'.tr),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                AtharIconButton(
                  // Mirrors itself in Arabic: points back to the start side.
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'adhkar_previous'.tr,
                  variant: AtharIconButtonVariant.outlined,
                  onPressed: _page > 0 ? () => _to(_page - 1) : null,
                ),
                Expanded(
                  child: Text(
                    'adhkar_position'.trParams({
                      'n': '${_page + 1}',
                      'total': '${widget.count}',
                    }),
                    textAlign: TextAlign.center,
                    style: context.type.bodyStrong.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                AtharIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'adhkar_next'.tr,
                  variant: AtharIconButtonVariant.outlined,
                  onPressed: _page < widget.count - 1
                      ? () => _to(_page + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
