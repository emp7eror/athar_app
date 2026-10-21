import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/ui/athar_ui.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../core/utils/widget_image_exporter.dart';
import 'share_card.dart';

/// Previews [content] as an image card and shares it — the ayah card and the
/// Adhkar & Duas card both open this.
///
/// The reader picks a design and a format; both are remembered for next time.
/// Colours follow the theme chosen in the app's appearance settings.
Future<void> showShareCardSheet(
  BuildContext context, {
  required String title,
  required ShareCardContent content,
  required String plainText,
  required String filename,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ShareCardSheet(
      title: title,
      content: content,
      plainText: plainText,
      filename: filename,
    ),
  );
}

class ShareCardSheet extends StatefulWidget {
  const ShareCardSheet({
    super.key,
    required this.title,
    required this.content,
    required this.plainText,
    required this.filename,
  });

  final String title;
  final ShareCardContent content;

  /// Sent with the image, and what Copy puts on the clipboard.
  final String plainText;
  final String filename;

  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  static const _kDesign = 'share_card_design';
  static const _kFormat = 'share_card_format';
  static const _kNote = 'share_card_show_note';

  final _box = GetStorage();
  final _cardKey = GlobalKey();
  late ShareCardDesign _design = ShareCardDesign.byName(
    _box.read(_kDesign) as String?,
  );
  late ShareCardFormat _format = ShareCardFormat.byName(
    _box.read(_kFormat) as String?,
  );
  late bool _showNote = (_box.read(_kNote) as bool?) ?? false;
  bool _sharing = false;

  ShareCardPalette get _palette =>
      ShareCardPalette.of(Get.find<ThemeController>().preset);

  void _setDesign(ShareCardDesign d) {
    setState(() => _design = d);
    _box.write(_kDesign, d.name);
  }

  void _setFormat(ShareCardFormat f) {
    setState(() => _format = f);
    _box.write(_kFormat, f.name);
  }

  void _setNote(bool v) {
    setState(() => _showNote = v);
    _box.write(_kNote, v);
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final path = await WidgetImageExporter.captureToFile(
        _cardKey,
        filename: widget.filename,
      );
      if (path == null) throw StateError('share card not mounted');
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: widget.plainText),
      );
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      AppSnackbar.error(widget.title, 'share_card_failed'.tr);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.plainText));
    AppSnackbar.show(widget.title, 'share_card_copied'.tr);
  }

  ShareCard _card(ShareCardDesign design) => ShareCard(
    content: widget.content,
    design: design,
    palette: _palette,
    format: _format,
    showNote: _showNote,
  );

  @override
  Widget build(BuildContext context) {
    final hasNote = widget.content.note != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(
                AtharSpace.screen,
                0,
                AtharSpace.screen,
                AtharSpace.md,
              ),
              children: [
                Text(widget.title, style: context.type.sectionTitle),
                const SizedBox(height: AtharSpace.md),
                // Previewed at the sheet's width; captured at the card's own size.
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AtharRadius.card),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AtharRadius.card),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: _card(_design),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AtharSpace.lg),
                Text('share_card_design'.tr, style: context.type.overline),
                const SizedBox(height: AtharSpace.xs),
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ShareCardDesign.values.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AtharSpace.sm),
                    itemBuilder: (_, i) {
                      final d = ShareCardDesign.values[i];
                      return _DesignThumb(
                        label: d.labelKey.tr,
                        selected: d == _design,
                        onTap: () => _setDesign(d),
                        child: _card(d),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AtharSpace.md),
                Text('share_card_format'.tr, style: context.type.overline),
                const SizedBox(height: AtharSpace.xs),
                AtharSegmented<ShareCardFormat>(
                  segments: [
                    for (final f in ShareCardFormat.values)
                      AtharSegment(
                        value: f,
                        label: f.labelKey.tr,
                        icon: f == ShareCardFormat.story
                            ? Icons.stay_current_portrait_rounded
                            : Icons.crop_portrait_rounded,
                      ),
                  ],
                  selected: _format,
                  onChanged: _setFormat,
                ),
                if (hasNote)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _showNote,
                    onChanged: _setNote,
                    title: Text('share_card_show_virtue'.tr),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AtharSpace.screen,
                AtharSpace.xs,
                AtharSpace.screen,
                AtharSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AtharButton(
                      label: 'share_card_share'.tr,
                      icon: Icons.ios_share_rounded,
                      loading: _sharing,
                      expand: true,
                      onPressed: _share,
                    ),
                  ),
                  const SizedBox(width: AtharSpace.sm),
                  Expanded(
                    child: AtharButton(
                      label: 'share_card_copy'.tr,
                      icon: Icons.copy_rounded,
                      variant: AtharButtonVariant.secondary,
                      expand: true,
                      onPressed: _copy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A design, shown as a small live card with its name.
class _DesignThumb extends StatelessWidget {
  const _DesignThumb({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: AtharMotion.fast,
              width: 62,
              height: 104,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AtharRadius.sm + 2),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.4 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AtharRadius.sm),
                // Thumbnails show the top of the card, where each design differs most.
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  child: IgnorePointer(child: child),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
