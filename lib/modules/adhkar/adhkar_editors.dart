import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../../core/utils/snackbar.dart';
import 'adhkar_icons.dart';
import 'adhkar_models.dart';
import 'adhkar_store.dart';

/// Runs a change to the reader's collections with a spinner, and reports the
/// outcome honestly: success only once the server has it.
Future<T?> runAdhkarAction<T>(
  RxBool busy,
  Future<T> Function() action, {
  String? success,
}) async {
  if (busy.value) return null; // a second tap while the first is saving
  busy.value = true;
  try {
    final result = await action();
    if (success != null) AppSnackbar.show('adhkar_title'.tr, success);
    return result;
  } on AdhkarActionException catch (e) {
    AppSnackbar.error('adhkar_title'.tr, e.message);
    return null;
  } finally {
    busy.value = false;
  }
}

/// Create a collection, or edit one's name, description and category.
class AdhkarCollectionEditor extends StatefulWidget {
  const AdhkarCollectionEditor({super.key, required this.type, this.existing});

  final AdhkarType type;
  final AdhkarCollection? existing;

  /// The saved collection, or null when cancelled or failed.
  static Future<AdhkarCollection?> show(
    BuildContext context, {
    required AdhkarType type,
    AdhkarCollection? existing,
  }) => showAtharSheet<AdhkarCollection>(
    context: context,
    builder: (_) => AdhkarCollectionEditor(type: type, existing: existing),
  );

  @override
  State<AdhkarCollectionEditor> createState() => _AdhkarCollectionEditorState();
}

class _AdhkarCollectionEditorState extends State<AdhkarCollectionEditor> {
  final _store = Get.find<AdhkarStore>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late int? _categoryId = widget.existing?.categoryId;

  /// The chosen icon's key; the collection's current one, or the kind's.
  late String _icon =
      widget.existing?.icon ??
      (widget.type == AdhkarType.dua ? 'volunteer_activism' : 'auto_stories');
  final _busy = false.obs;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'adhkar_name_required'.tr);
      return;
    }
    final description = _description.text.trim().isEmpty
        ? null
        : _description.text.trim();
    final existing = widget.existing;
    final saved = await runAdhkarAction(
      _busy,
      () => existing == null
          ? _store.createCollection(
              type: widget.type,
              name: name,
              description: description,
              icon: _icon,
              categoryId: _categoryId,
            )
          : _store.updateCollection(
              existing,
              name: name,
              description: description,
              icon: _icon,
              categoryId: _categoryId,
            ),
      success: existing == null
          ? 'adhkar_collection_created'.tr
          : 'adhkar_saved'.tr,
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _store.duaCategories;
    // A category that has since been hidden is no longer offered.
    if (_categoryId != null && !categories.any((c) => c.id == _categoryId)) {
      _categoryId = null;
    }

    return _SheetBody(
      title: widget.existing == null
          ? 'adhkar_new_collection'.tr
          : 'adhkar_edit_collection'.tr,
      busy: _busy,
      onSave: _save,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.existing == null,
          maxLength: 255,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'adhkar_collection_name'.tr,
            errorText: _error,
          ),
        ),
        const SizedBox(height: AtharSpace.sm),
        TextField(
          controller: _description,
          maxLength: 1000,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'adhkar_collection_description'.tr,
          ),
        ),
        const SizedBox(height: AtharSpace.sm),
        Text('adhkar_collection_icon'.tr, style: context.type.overline),
        const SizedBox(height: AtharSpace.xs),
        _IconPicker(
          selected: _icon,
          onChanged: (key) => setState(() => _icon = key),
        ),
        if (widget.type == AdhkarType.dua && categories.isNotEmpty) ...[
          const SizedBox(height: AtharSpace.sm),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            decoration: InputDecoration(labelText: 'adhkar_category'.tr),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text('adhkar_no_category'.tr),
              ),
              for (final c in categories)
                DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        ],
      ],
    );
  }
}

/// The icons a collection can take, as a grid of round choices.
class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Wrap(
      spacing: AtharSpace.xs,
      runSpacing: AtharSpace.xs,
      children: [
        for (final MapEntry(key: key, value: icon) in adhkarIcons.entries)
          Semantics(
            button: true,
            selected: key == selected,
            child: InkResponse(
              onTap: () => onChanged(key),
              radius: 26,
              child: AnimatedContainer(
                duration: AtharMotion.fast,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: key == selected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                ),
                child: Icon(
                  icon,
                  size: AtharSize.iconLg,
                  color: key == selected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Add a dhikr or dua the reader writes, or edit one in their collection.
class AdhkarItemEditor extends StatefulWidget {
  const AdhkarItemEditor({super.key, required this.collection, this.existing});

  final AdhkarCollection collection;
  final AdhkarItem? existing;

  static Future<AdhkarCollection?> show(
    BuildContext context, {
    required AdhkarCollection collection,
    AdhkarItem? existing,
  }) => showAtharSheet<AdhkarCollection>(
    context: context,
    builder: (_) =>
        AdhkarItemEditor(collection: collection, existing: existing),
  );

  @override
  State<AdhkarItemEditor> createState() => _AdhkarItemEditorState();
}

class _AdhkarItemEditorState extends State<AdhkarItemEditor> {
  final _store = Get.find<AdhkarStore>();
  late final _text = TextEditingController(text: widget.existing?.text ?? '');
  // Once by default; every dhikr or dua the reader writes has a count.
  late final _target = TextEditingController(
    text: '${widget.existing?.target ?? 1}',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  final _busy = false.obs;
  String? _textError;
  String? _targetError;

  AdhkarType get _type => widget.collection.type;

  @override
  void dispose() {
    for (final c in [_text, _target, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    final target = int.tryParse(_target.text.trim());
    setState(() {
      _textError = text.isEmpty ? 'adhkar_text_required'.tr : null;
      _targetError = target == null || target < 1 || target > 100000
          ? 'adhkar_target_invalid'.tr
          : null;
    });
    if (_textError != null || _targetError != null) return;

    final existing = widget.existing;
    final notes = _notes.text.trim();
    final fields = {
      'text': text,
      'target_count': target,
      'notes': notes.isEmpty ? null : notes,
      // Not shown here, but kept: a copied item's occasion, source and
      // virtue stay as they were.
      'occasion': existing?.occasion,
      'reference': existing?.reference,
      'virtue': existing?.virtue,
    };
    final saved = await runAdhkarAction(
      _busy,
      () => existing == null
          ? _store.addItem(widget.collection, fields)
          : _store.updateItem(existing, fields),
      success: existing == null
          ? adhkarWord('adhkar_added', _type)
          : 'adhkar_saved'.tr,
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBody(
      title: widget.existing == null
          ? adhkarWord('adhkar_new', _type)
          : adhkarWord('adhkar_edit', _type),
      busy: _busy,
      onSave: _save,
      children: [
        TextField(
          controller: _text,
          autofocus: widget.existing == null,
          minLines: 3,
          maxLines: 8,
          maxLength: 5000,
          style: context.text.titleMedium?.copyWith(height: 1.8),
          decoration: InputDecoration(
            labelText: adhkarWord('adhkar_text', _type),
            errorText: _textError,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AtharSpace.xs),
        TextField(
          controller: _target,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'adhkar_target'.tr,
            errorText: _targetError,
          ),
        ),
        const SizedBox(height: AtharSpace.md),
        TextField(
          controller: _notes,
          minLines: 1,
          maxLines: 4,
          maxLength: 5000,
          decoration: InputDecoration(labelText: 'adhkar_notes_optional'.tr),
        ),
      ],
    );
  }
}

/// Copies the chosen public items into one of the reader's collections of the
/// same kind, or a new one. True once they are saved.
class AdhkarCopyToSheet extends StatefulWidget {
  const AdhkarCopyToSheet({super.key, required this.items, required this.type});

  final List<AdhkarItem> items;
  final AdhkarType type;

  static Future<bool> show(
    BuildContext context, {
    required List<AdhkarItem> items,
    required AdhkarType type,
  }) async =>
      await showAtharSheet<bool>(
        context: context,
        builder: (_) => AdhkarCopyToSheet(items: items, type: type),
      ) ??
      false;

  @override
  State<AdhkarCopyToSheet> createState() => _AdhkarCopyToSheetState();
}

class _AdhkarCopyToSheetState extends State<AdhkarCopyToSheet> {
  final _store = Get.find<AdhkarStore>();
  final _busy = false.obs;

  Future<void> _copyInto(AdhkarCollection into) async {
    final saved = await runAdhkarAction(
      _busy,
      () => _store.copyItems(into, widget.items),
      success: 'adhkar_item_copied'.trParams({'name': into.name}),
    );
    if (saved != null && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _newCollection() async {
    final created = await AdhkarCollectionEditor.show(
      context,
      type: widget.type,
    );
    if (created != null) await _copyInto(created);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        // Only collections of the same kind: a Dua goes into a Dua
        // collection, an Adhkar into an Adhkar one.
        final mine = _store.mine.where((c) => c.type == widget.type).toList();
        return Stack(
          children: [
            ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: AtharSpace.lg),
              children: [
                AtharSheetHeader(
                  title: adhkarCopyLabel(widget.type, widget.items.length),
                  subtitle: 'adhkar_copy_item_sub'.tr,
                ),
                AtharListGroup(
                  children: [
                    AtharListRow(
                      icon: Icons.add_rounded,
                      title: 'adhkar_new_collection'.tr,
                      onTap: _busy.value ? null : _newCollection,
                    ),
                    for (final c in mine)
                      AtharListRow(
                        icon: adhkarIconFor(c),
                        title: c.name,
                        subtitle: adhkarCountLabel(c.type, c.items.length),
                        onTap: _busy.value ? null : () => _copyInto(c),
                      ),
                  ],
                ),
              ],
            ),
            if (_busy.value)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }),
    );
  }
}

/// «نسخ دعاء واحد / دعاءين / ٣ أدعية / ١١ دعاءً إلى مجموعاتي» — the copy
/// button's label for [n] chosen items; «نسخ الكل» when none are chosen.
String adhkarCopyLabel(AdhkarType type, int n) {
  if (n <= 0) return 'adhkar_copy_all'.tr;
  final kind = type == AdhkarType.dua ? 'dua' : 'dhikr';
  final form = switch (n) {
    1 => 'one',
    2 => 'two',
    <= 10 => 'few',
    _ => 'many',
  };
  return 'adhkar_copy_${kind}_$form'.trParams({'n': '$n'});
}

/// A form in a sheet with a save button that shows progress.
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.children,
    required this.onSave,
    required this.busy,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final RxBool busy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AtharSpace.lg,
            0,
            AtharSpace.lg,
            AtharSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtharSheetHeader(title: title),
              ...children,
              const SizedBox(height: AtharSpace.md),
              Text(
                'adhkar_needs_internet_hint'.tr,
                style: context.type.caption,
              ),
              const SizedBox(height: AtharSpace.sm),
              Obx(
                () => AtharButton(
                  label: 'save'.tr,
                  loading: busy.value,
                  expand: true,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
