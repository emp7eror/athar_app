import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'quran_page_cache.dart';

/// One Mushaf page.
///
/// The page is drawn straight from its vector source rather than being
/// rasterised first, so it stays sharp at any size and costs a few hundred
/// kilobytes instead of the several megabytes a decoded bitmap of the same page
/// would occupy.
class QuranPageSheet extends StatefulWidget {
  const QuranPageSheet({
    super.key,
    required this.url,
    required this.ground,
    required this.nightMode,
    required this.active,
  });

  final String url;

  /// The Mushaf is ink on a transparent ground, so the paper is painted here.
  /// Without it the page behind would read straight through this one.
  final Color ground;

  final bool nightMode;

  /// Whether this page is near enough to the reader to be worth fetching.
  ///
  /// The book builds all 604 sheets at once — it is a
  /// [MultiChildRenderObjectWidget], so there is no laziness to lean on — and
  /// an ungated sheet starts its own download the moment it is constructed.
  /// That is 604 requests on opening the Mushaf. A sheet outside the window is
  /// just its paper colour until the reader comes near it.
  final bool active;

  @override
  State<QuranPageSheet> createState() => _QuranPageSheetState();
}

class _QuranPageSheetState extends State<QuranPageSheet> {
  /// Page bytes already read off disk. Small enough to keep several — the whole
  /// point of dropping the bitmap cache.
  static final Map<String, Uint8List> _memo = <String, Uint8List>{};
  static const _maxHeld = 8;

  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(QuranPageSheet old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() {
        _bytes = null;
        _failed = false;
      });
      if (widget.active) _load();
      return;
    }

    // The reader has come within reach of a page that was holding off.
    if (widget.active && !old.active && _bytes == null && !_failed) _load();
  }

  Future<void> _load() async {
    final url = widget.url;
    if (url.isEmpty) return;

    final held = _memo[url];
    if (held != null) {
      setState(() => _bytes = held);
      return;
    }

    final file = await QuranPageCache.fetch(url);
    if (!mounted || url != widget.url) return;

    if (file == null) {
      setState(() => _failed = true);
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (!mounted || url != widget.url) return;

      _memo[url] = bytes;
      if (_memo.length > _maxHeld) _memo.remove(_memo.keys.first);

      setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;

    // A page the reader hasn't reached shows its paper and nothing else — no
    // spinner, because nothing is loading and none is owed.
    if (!widget.active && bytes == null) return ColoredBox(color: widget.ground);

    return ColoredBox(
      // color: Colors.green,
      color: widget.ground,
      child: _failed
          ? _Message(text: 'quran_page_unavailable'.tr)
          : bytes == null
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _maybeInverted(
                  SvgPicture.memory(
                    bytes,
                    // The Mushaf's own proportions are kept; the script is
                    // never stretched or cropped.
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholderBuilder: (_) => const SizedBox.shrink(),
                  ),
                ),
    );
  }

  /// Night reading flips the ink to light without touching the paper, which is
  /// painted underneath and therefore outside the filter.
  Widget _maybeInverted(Widget child) {
    if (!widget.nightMode) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255, //
        0, 0, -1, 0, 255, //
        0, 0, 0, 1, 0, //
      ]),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF8A7C63), size: 30),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8A7C63), fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
