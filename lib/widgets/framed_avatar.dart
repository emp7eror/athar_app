import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A user's avatar (photo, or an initial-letter fallback) rendered inside
/// their current level's frame asset. Every place in the app that shows a
/// user photo — leaderboard, profile, friends list/requests, the level-up
/// popup, the achievement share card, and the profile preview modal — goes
/// through this single widget so a frame appears consistently everywhere.
///
/// [frameAsset] is the path returned by the backend (e.g.
/// `assets/frames/frame_3.png`). If the file doesn't exist yet in the bundle,
/// the frame silently renders nothing rather than crashing — see
/// `assets/frames/README.md`.
class FramedAvatar extends StatelessWidget {
  const FramedAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.frameAsset,
    this.radius = 24,
    this.backgroundColor,
    this.glow = true,
    this.level,
  });

  final String name;
  final String? avatarUrl;
  final String? frameAsset;
  final double radius;
  final Color? backgroundColor;

  /// Golden halo behind the avatar. On by default; pass false where the
  /// surrounding design already carries its own emphasis.
  final bool glow;

  /// The user's level (1..5). The halo grows with rank, so a higher level is
  /// visible at a glance. Null falls back to the faintest glow.
  final int? level;

  /// Levels run 1..5 — maps rank onto 0..1 so the halo can scale smoothly.
  double get _rankFactor {
    final l = (level ?? 1).clamp(1, 5);
    return (l - 1) / 4;
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
          if (frameAsset != null && frameAsset!.isNotEmpty)
            // Slightly larger than the avatar so the ring/border sits
            // outside the photo instead of covering it.
            SizedBox(
              width: size * 1.28,
              height: size * 1.28,
              child: Image.asset(
                frameAsset!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
