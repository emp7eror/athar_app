import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/coach_insight_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/prayer_insights_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/storage_provider.dart';
import 'coach_controller.dart';

/// The AI coaching page — reached from the Home screen's floating button.
/// Deliberately not a tab: it's an occasional read, not something the user
/// needs one tap away at all times.
class CoachView extends GetView<CoachController> {
  const CoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.psychology_rounded,
              color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Text('coach_title'.tr),
        ]),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Obx(() {
            if (controller.loading.value && controller.insights.value == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.failed.value && controller.insights.value == null) {
              return _CenteredMessage(
                icon: Icons.wifi_off_rounded,
                message: 'legal_load_failed'.tr,
                onRetry: controller.load,
              );
            }

            final cards = _cards();
            if (cards.isEmpty) {
              return _CenteredMessage(
                icon: Icons.insights_rounded,
                message: 'coach_insufficient_data'.tr,
                onRetry: controller.load,
              );
            }

            final section = controller.insights.value?.section;
            final isAiGenerated = (section?.cards ?? const []).isNotEmpty;
            final userTitle = section?.userTitle;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isAiGenerated) ...[
                  Row(children: [const _AiBadge()]),
                  const SizedBox(height: 14),
                ],
                if (userTitle != null && userTitle.label.isNotEmpty) ...[
                  _UserTitleCard(title: userTitle),
                  const SizedBox(height: 16),
                ],
                for (final c in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _coachCard(context, c),
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
  /// server and fallback paths render through the same card widget.
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

  Widget _coachCard(BuildContext context, CoachInsight c) {
    final color = switch (c.tone) {
      CoachTone.positive => AppColors.success,
      CoachTone.warning => AppColors.warning,
      CoachTone.info => Theme.of(context).colorScheme.primary,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(c.icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                const SizedBox(height: 4),
                Text(c.message, style: const TextStyle(fontSize: 13, height: 1.4)),
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
    final athar = context.athar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: athar.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_rounded, color: athar.gold, size: 30),
          const SizedBox(height: 10),
          Text(
            title.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (title.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              title.reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small "Powered by AI" pill — only shown when the cards on screen are
/// genuinely the server's AI-generated ones.
class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            'ai_powered_badge'.tr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // ListView (not Column) so pull-to-refresh still works on an empty state.
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(icon, size: 44, color: context.athar.textMuted),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.athar.textMuted, height: 1.5),
        ),
        const SizedBox(height: 18),
        Center(child: OutlinedButton(onPressed: onRetry, child: Text('retry'.tr))),
      ],
    );
  }
}
