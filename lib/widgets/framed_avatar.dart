import 'package:flutter/material.dart';

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
  });

  final String name;
  final String? avatarUrl;
  final String? frameAsset;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final finalRadius=radius*1.8;
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final size = finalRadius * 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
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
