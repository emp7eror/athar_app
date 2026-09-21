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
/// Frames come from one of two places. [frameAsset] is bundled with the app
/// (`assets/frames/frame_3.png`) and is what the levels shipped in this build
/// use: instant and offline. [frameUrl] is sent by the server for levels added
/// since, and is downloaded once and cached on disk.
///
/// The url wins when both are given, falling back to the asset if the download
/// fails. If neither resolves, the frame renders nothing rather than crashing
/// — see `assets/frames/README.md`.
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

  /// Frame artwork for a level added after this build shipped.
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

/// The frame image: the downloaded one when the server named it, the bundled
/// asset otherwise. Nothing renders while a download is in flight, so a frame
/// never flashes a placeholder.
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

  void _start() {
    final url = widget.url;
    _download = (url == null || url.isEmpty) ? null : DefaultCacheManager().getSingleFile(url);
  }

  Widget _asset() {
    final asset = widget.asset;
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
