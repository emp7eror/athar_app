import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../widgets/framed_avatar.dart';

/// Opens the tap-to-preview modal for [userId] (from a leaderboard row, or a
/// friend-leveled-up notification tap). [rank] is optional — the leaderboard
/// row already knows the tapped user's rank; a notification tap doesn't, so
/// the header simply omits it when null.
void openProfilePreview(int userId, {int? rank}) {
  final context = Get.context;
  if (context == null) return;
  showAtharSheet<void>(
    context: context,
    builder: (_) => ProfilePreviewModal(userId: userId, rank: rank),
  );
}

class PublicProfile {
  final int id;
  final String name, userCode;
  final String? avatarPath, avatarUrl;
  final int score, lastScore, bestScore, totalPoints, currentStreak, maxStreak;
  final LevelInfo level;
  final String friendshipStatus; // self | accepted | pending_sent | pending_received | none

  PublicProfile({
    required this.id,
    required this.name,
    required this.userCode,
    this.avatarPath,
    this.avatarUrl,
    required this.score,
    required this.lastScore,
    required this.bestScore,
    required this.totalPoints,
    required this.currentStreak,
    required this.maxStreak,
    required this.level,
    required this.friendshipStatus,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        id: j['id'],
        name: j['name'] ?? '',
        userCode: j['user_code'] ?? '',
        avatarPath: j['avatar_url'],
        avatarUrl: j['avatar_url'],
        score: j['score'] ?? 0,
        lastScore: j['last_score'] ?? 0,
        bestScore: j['best_score'] ?? 0,
        totalPoints: j['total_points'] ?? 0,
        currentStreak: j['current_streak'] ?? 0,
        maxStreak: j['max_streak'] ?? 0,
        level: LevelInfo.fromJson(j['level'] ?? {}),
        friendshipStatus: j['friendship_status'] ?? 'none',
      );
}

class ProfilePreviewController extends GetxController {
  ProfilePreviewController(this.userId);
  final int userId;
  final _api = Get.find<ApiProvider>();

  final loading = true.obs;
  final failed = false.obs;
  final acting = false.obs;
  final profile = Rxn<PublicProfile>();

  Future<void> load() async {
    loading.value = true;
    failed.value = false;
    try {
      final res = await _api.userProfile(userId);
      profile.value = PublicProfile.fromJson(res);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      failed.value = true;
    } finally {
      loading.value = false;
    }
  }

  Future<void> addFriend() async {
    if (acting.value) return;
    acting.value = true;
    try {
      await _api.addFriendById(userId);
      AppSnackbar.show('friends'.tr, 'add_friend'.tr, position: SnackPosition.BOTTOM);
      await load();
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      AppSnackbar.error('friends'.tr, e.message, position: SnackPosition.BOTTOM);
    } finally {
      acting.value = false;
    }
  }

  Future<void> removeFriend() async {
    final p = profile.value;
    if (p == null || acting.value) return;

    final confirmed = await showAtharConfirm(
      title: 'remove_friend_title'.tr,
      message: 'remove_friend_msg'.trParams({'name': p.name}),
      confirmLabel: 'remove'.tr,
      icon: Icons.person_remove_rounded,
      destructive: true,
    );
    if (!confirmed) return;

    acting.value = true;
    try {
      await _api.removeFriend(userId);
      AppSnackbar.show('friends'.tr, 'friend_removed'.tr, position: SnackPosition.BOTTOM);
      await load();
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      AppSnackbar.error('friends'.tr, e.message, position: SnackPosition.BOTTOM);
    } finally {
      acting.value = false;
    }
  }
}

class ProfilePreviewModal extends StatefulWidget {
  const ProfilePreviewModal({super.key, required this.userId, this.rank});

  final int userId;
  final int? rank;

  @override
  State<ProfilePreviewModal> createState() => _ProfilePreviewModalState();
}

class _ProfilePreviewModalState extends State<ProfilePreviewModal> {
  late final controller = ProfilePreviewController(widget.userId);

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, scrollController) => Obx(() {
        if (controller.loading.value && controller.profile.value == null) {
          return const AtharLoadingState();
        }
        final p = controller.profile.value;
        if (p == null) {
          return AtharErrorState(message: 'legal_load_failed'.tr, onRetry: controller.load);
        }

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(AtharSpace.screen, 0, AtharSpace.screen, AtharSpace.xl),
          children: [
            _Header(profile: p, rank: widget.rank, isAr: isAr),
            const SizedBox(height: AtharSpace.lg),
            _Statistics(profile: p),
            const SizedBox(height: AtharSpace.md),
            _Achievement(profile: p, isAr: isAr),
            const SizedBox(height: AtharSpace.md),
            _Social(controller: controller, profile: p),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.rank, required this.isAr});

  final PublicProfile profile;
  final int? rank;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FramedAvatar(
          name: profile.name,
          avatarUrl: profile.avatarUrl,
          frameAsset: profile.level.frame,
          level: profile.level.level,
          radius: 30,
        ),
        const SizedBox(height: AtharSpace.sm),
        Semantics(
          header: true,
          child: Text(profile.name, textAlign: TextAlign.center, style: context.text.headlineSmall),
        ),
        Text(profile.level.displayName(isAr), style: context.type.caption),
        if (rank != null) ...[
          const SizedBox(height: AtharSpace.xs),
          AtharBadge(label: '${'rank'.tr} #$rank', icon: Icons.emoji_events_rounded, tone: AtharTone.gold),
        ],
      ],
    );
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    return AtharCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AtharStat(
                  icon: Icons.star_rounded,
                  tone: AtharTone.gold,
                  value: '${profile.totalPoints}',
                  label: 'points'.tr,
                  center: true,
                ),
              ),
              Expanded(
                child: AtharStat(
                  icon: Icons.local_fire_department_rounded,
                  tone: AtharTone.warning,
                  value: '${profile.currentStreak}',
                  label: 'streak'.tr,
                  center: true,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AtharSpace.md),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: AtharStat(
                  icon: Icons.calendar_month_rounded,
                  value: '${profile.score}',
                  label: 'current_month_score'.tr,
                  center: true,
                ),
              ),
              Expanded(
                child: AtharStat(
                  icon: Icons.history_rounded,
                  tone: AtharTone.neutral,
                  value: '${profile.lastScore}',
                  label: 'last_month_score'.tr,
                  center: true,
                ),
              ),
              Expanded(
                child: AtharStat(
                  icon: Icons.military_tech_rounded,
                  tone: AtharTone.gold,
                  value: '${profile.bestScore}',
                  label: 'best_score'.tr,
                  center: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Achievement extends StatelessWidget {
  const _Achievement({required this.profile, required this.isAr});

  final PublicProfile profile;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final atMax = profile.level.nextAt == null;

    return AtharCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('current_level'.tr, style: context.type.caption),
          Text(profile.level.displayName(isAr), style: context.type.sectionTitle),
          const SizedBox(height: AtharSpace.sm),
          AtharProgressBar(
            value: profile.level.progress.clamp(0, 1).toDouble(),
            color: context.athar.gold,
            semanticsLabel: 'progress_to_next'.tr,
          ),
          const SizedBox(height: AtharSpace.xs),
          Text(atMax ? 'max_level_reached'.tr : 'progress_to_next'.tr, style: context.type.caption),
        ],
      ),
    );
  }
}

class _Social extends StatelessWidget {
  const _Social({required this.controller, required this.profile});

  final ProfilePreviewController controller;
  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.acting.value;

      switch (profile.friendshipStatus) {
        case 'self':
          return const SizedBox.shrink();
        case 'accepted':
          return AtharButton(
            label: 'remove_friend'.tr,
            icon: Icons.person_remove_rounded,
            variant: AtharButtonVariant.secondary,
            expand: true,
            onPressed: busy ? null : controller.removeFriend,
          );
        case 'pending_sent':
        case 'pending_received':
          return AtharButton(
            label: 'friendship_pending'.tr,
            icon: Icons.hourglass_top_rounded,
            variant: AtharButtonVariant.secondary,
            expand: true,
            onPressed: null,
          );
        default:
          return const SizedBox.shrink();
      }
    });
  }
}
