import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('remove_friend_title'.tr),
        content: Text('remove_friend_msg'.trParams({'name': p.name})),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('remove'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

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
    final palette = context.athar;
    final isAr = Get.locale?.languageCode == 'ar';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Obx(() {
          if (controller.loading.value && controller.profile.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = controller.profile.value;
          if (p == null) {
            return Center(child: Text('app_name'.tr));
          }

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _header(context, p, isAr),
              const SizedBox(height: 24),
              _statisticsSection(context, p),
              const SizedBox(height: 24),
              _achievementSection(context, p, isAr),
              const SizedBox(height: 24),
              _socialSection(context, p),
            ],
          );
        }),
      ),
    );
  }

  Widget _header(BuildContext context, PublicProfile p, bool isAr) {
    print(widget.rank);
    return Column(
      children: [
        FramedAvatar(name: p.name, avatarUrl: p.avatarUrl, frameAsset: p.level.frame, radius: 35),
        const SizedBox(height: 12),
        Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        if (widget.rank != null) ...[
          const SizedBox(height: 6),
          Text('${'rank'.tr} #${widget.rank}',
              style: TextStyle(color: context.athar.textMuted, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _statisticsSection(BuildContext context, PublicProfile p) {
    return Column(
      children: [
        _statRow(context, [
          ('${p.score}', 'current_month_score'.tr),
          ('${p.bestScore}', 'best_score'.tr),
        ]),
        const SizedBox(height: 10),
        _statRow(context, [
          ('${p.lastScore}', 'last_month_score'.tr),
          ('${p.totalPoints}', 'points'.tr),
        ]),
      ],
    );
  }

  /// A row of equal-width [_statTile]s, laid out from (value, label) pairs.
  Widget _statRow(BuildContext context, List<(String, String)> tiles) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _statTile(context, tiles[i].$1, tiles[i].$2),
        ],
      ],
    );
  }

  Widget _statTile(BuildContext context, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: context.athar.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: context.athar.textMuted, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _achievementSection(BuildContext context, PublicProfile p, bool isAr) {
    final atMax = p.level.nextAt == null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.athar.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('current_level'.tr,
              style: TextStyle(color: context.athar.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(p.level.displayName(isAr),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.level.progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            atMax ? 'max_level_reached'.tr : 'progress_to_next'.tr,
            style: TextStyle(color: context.athar.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _socialSection(BuildContext context, PublicProfile p) {
    return Obx(() {
      final busy = controller.acting.value;
      switch (p.friendshipStatus) {
        case 'self':
          return const SizedBox.shrink();
        case 'accepted':
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : controller.removeFriend,
              icon: const Icon(Icons.person_remove_outlined),
              label: Text('remove_friend'.tr),
            ),
          );
        case 'pending_sent':
        case 'pending_received':
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: Text('friendship_pending'.tr),
            ),
          );
        default:
          return SizedBox(
            width: double.infinity,
            child:SizedBox()
            // ElevatedButton.icon(
            //   onPressed: busy ? null : controller.addFriend,
            //   icon: const Icon(Icons.person_add_alt_1),
            //   label: Text('add_friend'.tr),
            // ),
          );
      }
    });
  }
}
