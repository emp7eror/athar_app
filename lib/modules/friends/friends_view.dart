import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/friend_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/framed_avatar.dart';
import '../profile_preview/profile_preview_modal.dart';
import 'friends_controller.dart';

class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('friends'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _myCodeCard(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.codeInput,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        decoration: InputDecoration(counterText: '', hintText: 'enter_code'.tr),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: controller.add,
                      child: Text('add_friend'.tr, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (controller.pending.isNotEmpty) ...[
                  const Text('Pending requests', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...controller.pending.map(_pendingTile),
                  const SizedBox(height: 16),
                ],
                ...controller.friends.map((f) => _friendTile(context, f)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pendingTile(PendingRequest r) => Card(
    child: ListTile(
      leading: FramedAvatar(
        name: r.name,
        avatarUrl: r.avatarUrl,
        frameAsset: r.level?.frame,
        level: r.level?.level,
        radius: 20,
      ),
      title: Text(r.name),
      subtitle: Text(r.userCode),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.success),
            onPressed: () => controller.respond(r.friendshipId, 'accept'),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.danger),
            onPressed: () => controller.respond(r.friendshipId, 'reject'),
          ),
        ],
      ),
    ),
  );

  Widget _friendTile(BuildContext context, FriendModel f) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14)),
    child: Column(
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => openProfilePreview(f.id),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  FramedAvatar(
                    name: f.name,
                    avatarUrl: f.avatarUrl,
                    frameAsset: f.level?.frame,
                    level: f.level?.level,
                    radius: 15,
                  ),
                  // Streak badge, on the avatar instead of the crowded text
                  // row — only shown once there's actually a streak to show.
                  if (f.currentStreak > 0)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 2),
                            Text('${f.currentStreak}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(f.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${f.score}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Transform.translate(
                        offset: const Offset(0, -3),
                        child: Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => controller.nudge(f),
                    icon: const Icon(Icons.notifications_active_rounded, size: 20),
                    label: Text('nudge'.tr)
                  ),
                ],
              ),
            ),
          ],
        ),
        if (f.todayChecklist.isNotEmpty) ...[
          const SizedBox(height: 10),
          _prayerTicksRow(f.todayChecklist),
        ],


      ],
    ),
  );

  /// Small per-prayer tick/cross row — at a glance, which of today's 5
  /// prayers this friend has completed.
  Widget _prayerTicksRow(List<PrayerCheckItem> checklist) => Row(
    children: checklist.map((p) {
      final done = p.isCompleted;
      final onTime = p.isOnTime;
      return Expanded(
        child: Column(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: done ?( onTime?AppColors.secondary :AppColors.success) : AppColors.textMuted.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 2),
            Text(
              p.prayerName.tr,
              style: TextStyle(
                fontSize: 9,
                color: done ? AppColors.textMuted : AppColors.textMuted,
                fontWeight: done ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );

  Widget _myCodeCard() {
    final user = Get.find<StorageProvider>().cachedUser;
    final code = (user?['user_code'] ?? '------') as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'my_code'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // الكود بأحرف كبيرة مع مسافة بين كل حرف
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  code.split('').join('  '),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
              // زر النسخ
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  AppSnackbar.show('my_code'.tr, 'code_copied'.tr);
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                tooltip: 'copy'.tr,
              ),
              // زر المشاركة
              IconButton(
                onPressed: () => Share.share('${'share_code_msg'.tr} $code'),
                icon: const Icon(Icons.share_rounded, color: Colors.white70),
                tooltip: 'share'.tr,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('share_code_hint'.tr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
