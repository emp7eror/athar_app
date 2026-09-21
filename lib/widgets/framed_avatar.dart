import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../core/theme/app_theme.dart';

/// A user's avatar (photo, or an initial-letter fallback) rendered inside
/// their current level's frame asset. Every place in the app that shows a
/// user photo — leaderboard, profile, friends list/requests, the level-up
/// popup, the achievement share card, and the profile preview modal — goes
/// through this single widget so a frame appears consistently everywhere.
///
/// The frame comes from whichever source the server's value describes:
///
///  * `https://…`   — downloaded once and cached on disk. This is how a level
///    added after the app shipped gets its artwork.
///  * any other text — a file inside this build, e.g. `frame_6.png`, looked up
///    under `assets/frames/`.
///  * nothing at all — [frameAsset], the frame bundled for that level number.
///
/// Whatever the source, a frame that can't be loaded renders nothing rather
/// than crashing — see `assets/frames/README.md`.
class FramedAvatar extends StatelessWidget {
  const FramedAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.frameAsset,
    this.frameUrl,
    this.radius = 24,
    this.backgroundColor,
    this.glow = true,
    this.level,
  });

  final String name;
  final String? avatarUrl;
  final String? frameAsset;

  /// What the server says this level's frame is: a full http(s) URL to
  /// download, or the name of a file bundled with the app.
  final String? frameUrl;
  final double radius;
  final Color? backgroundColor;

  /// Golden halo behind the avatar. On by default; pass false where the
  /// surrounding design already carries its own emphasis.
  final bool glow;

  /// The user's level. The halo grows with rank, so a higher level is visible
  /// at a glance. Null falls back to the faintest glow.
  final int? level;

  /// The halo was designed across five steps; a level added beyond them keeps
  /// the brightest one rather than growing without limit.
  static const _haloSteps = 5;

  /// Maps rank onto 0..1 so the halo can scale smoothly.
  double get _rankFactor {
    final l = (level ?? 1).clamp(1, _haloSteps);
    return (l - 1) / (_haloSteps - 1);
  }

  static double _lerp(double from, double to, double t) => from + (to - from) * t;

  @override
  Widget build(BuildContext context) {
    final finalRadius=radius*1.8;
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final size = finalRadius * 2;
    final gold = context.athar.gold;
    final t = _rankFactor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Two layers: a tight core plus a soft outer bloom. Both are scaled
          // off the avatar size so the halo reads the same on a 13px header
          // avatar as on the large one in the level-up popup — and both grow
          // with [level], so rank is legible without reading a number.
          if (glow)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: _lerp(0.18, 0.38, t)),
                    blurRadius: finalRadius * _lerp(0.20, 0.36, t),
                    spreadRadius: finalRadius * _lerp(0.008, 0.04, t),
                  ),
                  BoxShadow(
                    color: gold.withValues(alpha: _lerp(0.06, 0.16, t)),
                    blurRadius: finalRadius * _lerp(0.35, 0.65, t),
                    spreadRadius: finalRadius * _lerp(0.02, 0.08, t),
                  ),
                ],
              ),
            ),
          (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? CircleAvatar(
                  radius: finalRadius,
                  backgroundImage: NetworkImage(avatarUrl!),
                  backgroundColor: bg,
                )
              : CircleAvatar(
                  radius: finalRadius,
                  backgroundColor: bg,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: radius * 0.72,
                    ),
                  ),
                ),
          if ((frameUrl != null && frameUrl!.isNotEmpty) || (frameAsset != null && frameAsset!.isNotEmpty))
            // Slightly larger than the avatar so the ring/border sits
            // outside the photo instead of covering it.
            SizedBox(
              width: size * 1.28,
              height: size * 1.28,
              child: _Frame(url: frameUrl, asset: frameAsset),
            ),
        ],
      ),
    );
  }
}

/// The frame image, resolved from the shape of what the server sent. Nothing
/// renders while a download is in flight, so a frame never flashes a
/// placeholder.
class _Frame extends StatefulWidget {
  const _Frame({required this.url, required this.asset});

  final String? url;
  final String? asset;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  /// Held in state rather than created in build, so a rebuild doesn't start
  /// the download again.
  Future<File>? _download;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_Frame old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _start();
  }

  /// A value that starts with http(s) is fetched; anything else is a file in
  /// this build and needs no network at all.
  static bool _isRemote(String? value) =>
      value != null && (value.startsWith('http://') || value.startsWith('https://'));

  void _start() {
    final url = widget.url;
    _download = _isRemote(url) ? DefaultCacheManager().getSingleFile(url!) : null;
  }

  /// The bundled frame: the name the server gave, or the one for this level.
  /// A bare name is looked up under `assets/frames/`; a full asset path is
  /// used as given.
  Widget _asset() {
    final named = widget.url;
    var asset = widget.asset;

    if (!_isRemote(named) && named != null && named.isNotEmpty) {
      asset = named.contains('/') ? named : 'assets/frames/$named';
    }

    if (asset == null || asset.isEmpty) return const SizedBox.shrink();

    return Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    final download = _download;
    if (download == null) return _asset();

    return FutureBuilder<File>(
      future: download,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.file(
            snapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _asset(),
          );
        }
        // Still downloading, or it failed: the bundled frame if there is one.
        return _asset();
      },
    );
  }
}
