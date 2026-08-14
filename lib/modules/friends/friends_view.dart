import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/friend_model.dart';
import 'friends_controller.dart';

class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() => ListView(padding: const EdgeInsets.all(16), children: [
              Text('friends'.tr,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: controller.codeInput,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'enter_code'.tr,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: controller.add,
                  child: Text('add_friend'.tr, style: const TextStyle(color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 16),
              if (controller.pending.isNotEmpty) ...[
                const Text('Pending requests',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ...controller.pending.map(_pendingTile),
                const SizedBox(height: 16),
              ],
              ...controller.friends.map((f) => _friendTile(context, f)),
            ])),
      ),
    );
  }

  Widget _pendingTile(PendingRequest r) => Card(
        child: ListTile(
          title: Text(r.name),
          subtitle: Text(r.userCode),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                icon: const Icon(Icons.check, color: AppColors.success),
                onPressed: () => controller.respond(r.friendshipId, 'accept')),
            IconButton(
                icon: const Icon(Icons.close, color: AppColors.danger),
                onPressed: () => controller.respond(r.friendshipId, 'reject')),
          ]),
        ),
      );

  Widget _friendTile(BuildContext context, FriendModel f) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('🔥 ${f.currentStreak}  •  ${f.totalPoints} ${'points'.tr}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
            ),
            TextButton.icon(
              onPressed: () => controller.nudge(f),
              icon: const Icon(Icons.notifications_active, size: 18),
              label: Text('nudge'.tr),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: f.todayProgress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: Theme.of(context).colorScheme.outline,
              color: AppColors.accent,
            ),
          ),
        ]),
      );
}
