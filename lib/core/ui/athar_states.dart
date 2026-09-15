import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../design/athar_tokens.dart';
import '../design/athar_typography.dart';
import '../theme/app_theme.dart';
import 'athar_button.dart';

/// Nothing to show yet — with what it would be and, where it helps, the way
/// to get there.
class AtharEmptyState extends StatelessWidget {
  const AtharEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Replaces the icon when an illustration asset exists for this state.
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AtharSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: AtharSize.iconXl, color: scheme.primary),
                ),
            const SizedBox(height: AtharSpace.md),
            Text(title, textAlign: TextAlign.center, style: context.type.sectionTitle),
            if (message != null) ...[
              const SizedBox(height: AtharSpace.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AtharSpace.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading, announced to screen readers.
class AtharLoadingState extends StatelessWidget {
  const AtharLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (message != null) ...[
              const SizedBox(height: AtharSpace.sm),
              Text(message!, style: context.type.caption, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// Something failed, with a way to try again.
class AtharErrorState extends StatelessWidget {
  const AtharErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AtharEmptyState(
      icon: icon,
      title: message,
      action: onRetry == null
          ? null
          : AtharButton(
              label: 'retry'.tr,
              icon: Icons.refresh_rounded,
              variant: AtharButtonVariant.secondary,
              onPressed: onRetry,
            ),
    );
  }
}

/// A placeholder block that gently pulses while content loads. Still when the
/// device asks for reduced motion.
class AtharSkeleton extends StatefulWidget {
  const AtharSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AtharRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AtharSkeleton> createState() => _AtharSkeletonState();
}

class _AtharSkeletonState extends State<AtharSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.55,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _pulse,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.colors.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
