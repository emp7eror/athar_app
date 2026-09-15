import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/coach_insight_engine.dart';
import '../../core/ui/athar_ui.dart';
import '../../data/models/prayer_insights_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/storage_provider.dart';
import 'coach_controller.dart';

/// The AI coaching page — reached from the button raised on the nav bar.
/// Deliberately not a tab: it's an occasional read, not something needed one
/// tap away at all times.
class CoachView extends GetView<CoachController> {
  const CoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AtharAppBar(title: 'coach_title'.tr),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Obx(() {
            if (controller.loading.value && controller.insights.value == null) {
              return const AtharLoadingState();
            }
            if (controller.failed.value && controller.insights.value == null) {
              return _Scrollable(
                child: AtharErrorState(message: 'coach_load_failed'.tr, onRetry: controller.load),
              );
            }

            final cards = _cards();
            if (cards.isEmpty) {
              return _Scrollable(
                child: AtharEmptyState(
                  icon: Icons.insights_rounded,
                  title: 'coach_insufficient_data'.tr,
                  action: AtharButton(
                    label: 'retry'.tr,
                    icon: Icons.refresh_rounded,
                    variant: AtharButtonVariant.secondary,
                    onPressed: controller.load,
                  ),
                ),
              );
            }

            final section = controller.insights.value?.section;
            final isAiGenerated = (section?.cards ?? const []).isNotEmpty;
            final userTitle = section?.userTitle;

            return ListView(
              padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, AtharSpace.xxl),
              children: [
                if (isAiGenerated) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AtharBadge(
                      label: 'ai_powered_badge'.tr,
                      icon: Icons.auto_awesome_rounded,
                      tone: AtharTone.brand,
                    ),
                  ),
                  const SizedBox(height: AtharSpace.md),
                ],
                if (userTitle != null && userTitle.label.isNotEmpty) ...[
                  _UserTitleCard(title: userTitle),
                  const SizedBox(height: AtharSpace.lg),
                ],
                for (final c in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtharSpace.sm),
                    child: _InsightCard(insight: c),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Prefers the section generated and stored server-side; the local
  /// rule-based engine is the fallback for when there is none (AI not
  /// configured, or it has never succeeded for this user yet).
  List<CoachInsight> _cards() {
    final data = controller.insights.value;
    if (data == null) return const [];

    final serverCards = data.section?.cards ?? const [];
    if (serverCards.isNotEmpty) {
      return serverCards.map(_fromServerCard).toList();
    }

    final u = _cachedUser();
    return CoachInsightEngine.build(
      data,
      currentStreak: u?.currentStreak ?? 0,
      maxStreak: u?.maxStreak ?? 0,
    );
  }

  UserModel? _cachedUser() {
    final u = Get.find<StorageProvider>().cachedUser;
    return u != null ? UserModel.fromJson(u) : null;
  }

  /// Server cards carry a tone but no icon — pick one to match, so both the
  /// server and fallback paths render through the same card.
  CoachInsight _fromServerCard(InsightCard c) {
    final tone = switch (c.tone) {
      'positive' => CoachTone.positive,
      'warning' => CoachTone.warning,
      _ => CoachTone.info,
    };

    final icon = switch (tone) {
      CoachTone.positive => Icons.emoji_events_rounded,
      CoachTone.warning => Icons.trending_down_rounded,
      CoachTone.info => Icons.insights_rounded,
    };

    return CoachInsight(icon: icon, tone: tone, title: c.title, message: c.message);
  }
}

/// Keeps pull-to-refresh working on a centred state.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final CoachInsight insight;

  @override
  Widget build(BuildContext context) {
    final tone = switch (insight.tone) {
      CoachTone.positive => AtharTone.success,
      CoachTone.warning => AtharTone.warning,
      CoachTone.info => AtharTone.brand,
    };

    return AtharCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tone.background(context), shape: BoxShape.circle),
            child: Icon(insight.icon, size: AtharSize.icon, color: tone.foreground(context)),
          ),
          const SizedBox(width: AtharSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: context.type.cardTitle.copyWith(color: tone.foreground(context))),
                const SizedBox(height: AtharSpace.xxs),
                Text(insight.message, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The honorific the coach awarded for this report, shown above the cards.
class _UserTitleCard extends StatelessWidget {
  const _UserTitleCard({required this.title});

  final UserTitle title;

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;

    return AtharCard(
      tone: AtharCardTone.brand,
      padding: const EdgeInsets.all(AtharSpace.lg),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_rounded, color: context.athar.gold, size: AtharSize.iconXl),
          const SizedBox(height: AtharSpace.sm),
          Text(
            title.label,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(color: onBrand),
          ),
          if (title.reason.isNotEmpty) ...[
            const SizedBox(height: AtharSpace.xs),
            Text(
              title.reason,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: onBrand.withValues(alpha: 0.85)),
            ),
          ],
        ],
      ),
    );
  }
}
