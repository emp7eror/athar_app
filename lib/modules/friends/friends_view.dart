import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/friend_model.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/framed_avatar.dart';
import '../profile_preview/profile_preview_modal.dart';
import '../tour/app_tours.dart';
import 'friends_controller.dart';

/// Friends: your code to share, adding someone by theirs, requests waiting for
/// you, and your friends with how their day of prayer is going.
class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});

  /// Room under the content for the floating nav bar.
  static const _navClearance = 160.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Obx(() {
            final friends = controller.friends;
            final pending = controller.pending;
            final firstLoad = controller.loading.value && friends.isEmpty && pending.isEmpty;

            return ListView(
              padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, _navClearance),
              // Keeps the whole page built so tour steps can scroll to any item.
              scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
              children: [
                AtharPageHeader(
                  title: 'friends'.tr,
                  trailing: const [TourHelpButton(pageId: TourPages.friends)],
                ),
                const SizedBox(height: AtharSpace.md),
                const TourTarget(id: TourTargets.friendsCode, child: _MyCodeCard()),
                const SizedBox(height: AtharSpace.sm),
                TourTarget(id: TourTargets.friendsAdd, child: _AddFriend(controller: controller)),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: AtharSpace.xl),
                  AtharListGroup(
                    title: '${'friends_pending_title'.tr} (${pending.length})',
                    children: [for (final r in pending) _PendingRow(request: r, controller: controller)],
                  ),
                ],
                const SizedBox(height: AtharSpace.xl),
                if (firstLoad)
                  for (var i = 0; i < 3; i++)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AtharSpace.xs),
                      child: AtharSkeleton(height: 96, radius: AtharRadius.card),
                    )
                else if (friends.isEmpty)
                  AtharEmptyState(
                    icon: Icons.group_add_rounded,
                    title: 'friends_empty_title'.tr,
                    message: 'friends_empty_msg'.tr,
                  )
                else ...[
                  AtharSectionHeader(
                    title: 'friends_list_title'.tr,
                    subtitle: '${friends.length}',
                  ),
                  AtharListGroup(
                    children: [
                      for (final (i, f) in friends.indexed)
                        i == 0
                            ? TourTarget(id: TourTargets.friendsFirst, child: _FriendRow(friend: f, controller: controller))
                            : _FriendRow(friend: f, controller: controller),
                    ],
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Your friend code, large and easy to read out, with copy and share.
class _MyCodeCard extends StatelessWidget {
  const _MyCodeCard();

  @override
  Widget build(BuildContext context) {
    final user = Get.find<StorageProvider>().cachedUser;
    final code = (user?['user_code'] ?? '------') as String;
    const onBrand = Colors.white;

    return AtharCard(
      tone: AtharCardTone.brand,
      padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.md, AtharSpace.xs, AtharSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('my_code'.tr, style: context.text.labelLarge?.copyWith(color: onBrand.withValues(alpha: 0.8))),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    code.split('').join(' '),
                    textDirection: TextDirection.ltr,
                    style: context.type.bigNumber.copyWith(color: onBrand, letterSpacing: 4),
                  ),
                ),
              ),
              AtharIconButton(
                icon: Icons.copy_rounded,
                tooltip: 'copy'.tr,
                color: onBrand,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  AppSnackbar.show('my_code'.tr, 'code_copied'.tr);
                },
              ),
              AtharIconButton(
                icon: Icons.share_rounded,
                tooltip: 'share'.tr,
                color: onBrand,
                onPressed: () => SharePlus.instance.share(ShareParams(text: '${'share_code_msg'.tr} $code')),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AtharSpace.md),
            child: Text(
              'share_code_hint'.tr,
              style: context.text.bodySmall?.copyWith(color: onBrand.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFriend extends StatelessWidget {
  const _AddFriend({required this.controller});

  final FriendsController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.codeInput,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.add(),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'enter_code'.tr,
              prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
        ),
        const SizedBox(width: AtharSpace.sm),
        AtharButton(label: 'add_friend'.tr, onPressed: controller.add),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.request, required this.controller});

  final PendingRequest request;
  final FriendsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.xs),
      child: Row(
        children: [
          FramedAvatar(
            name: request.name,
            avatarUrl: request.avatarUrl,
            frameAsset: request.level?.frame,
            level: request.level?.level,
            radius: 14,
            glow: false,
          ),
          const SizedBox(width: AtharSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(request.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                Text(request.userCode, textDirection: TextDirection.ltr, style: context.type.caption),
              ],
            ),
          ),
          AtharIconButton(
            icon: Icons.check_rounded,
            tooltip: 'friends_accept'.tr,
            variant: AtharIconButtonVariant.tonal,
            color: context.athar.success,
            onPressed: () => controller.respond(request.friendshipId, 'accept'),
          ),
          AtharIconButton(
            icon: Icons.close_rounded,
            tooltip: 'friends_decline'.tr,
            variant: AtharIconButtonVariant.tonal,
            color: context.colors.error,
            onPressed: () => controller.respond(request.friendshipId, 'reject'),
          ),
        ],
      ),
    );
  }
}

/// One friend: avatar with their streak, name and score, a nudge, and today's
/// five prayers at a glance.
class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.controller});

  final FriendModel friend;
  final FriendsController controller;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final streakFill = athar.warning;
    final onStreak = ThemeData.estimateBrightnessForColor(streakFill) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return InkWell(
      onTap: () => openProfilePreview(friend.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AtharSpace.md, AtharSpace.sm, AtharSpace.xs, AtharSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FramedAvatar(
                      name: friend.name,
                      avatarUrl: friend.avatarUrl,
                      frameAsset: friend.level?.frame,
                      level: friend.level?.level,
                      radius: 14,
                    ),
                    if (friend.currentStreak > 0)
                      PositionedDirectional(
                        bottom: -2,
                        end: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: streakFill,
                            borderRadius: BorderRadius.circular(AtharRadius.pill),
                            border: Border.all(color: athar.card, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded, size: 12, color: onStreak),
                              const SizedBox(width: 2),
                              Text(
                                '${friend.currentStreak}',
                                style: context.text.labelSmall?.copyWith(color: onStreak, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AtharSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(friend.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: AtharSize.iconSm, color: athar.gold),
                          const SizedBox(width: 2),
                          Text(
                            '${friend.score}',
                            style: context.type.caption.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AtharIconButton(
                  icon: Icons.notifications_active_rounded,
                  tooltip: 'nudge'.tr,
                  variant: AtharIconButtonVariant.tonal,
                  color: context.colors.primary,
                  onPressed: () => controller.nudge(friend),
                ),
              ],
            ),
            if (friend.todayChecklist.isNotEmpty) ...[
              const SizedBox(height: AtharSpace.sm),
              _TodayTicks(checklist: friend.todayChecklist),
            ],
          ],
        ),
      ),
    );
  }
}

/// Which of today's five prayers a friend has logged — icon and name for each,
/// so the state reads without colour.
class _TodayTicks extends StatelessWidget {
  const _TodayTicks({required this.checklist});

  final List<PrayerCheckItem> checklist;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final scheme = context.colors;

    return Row(
      children: [
        for (final p in checklist)
          Expanded(
            child: Semantics(
              label: '${p.prayerName.tr}: ${p.isCompleted ? (p.isOnTime ? 'performed_on_time'.tr : 'performed_outside_time'.tr) : 'friends_not_yet'.tr}',
              excludeSemantics: true,
              child: Column(
                children: [
                  Icon(
                    !p.isCompleted
                        ? Icons.radio_button_unchecked_rounded
                        : p.isOnTime
                            ? Icons.verified_rounded
                            : Icons.task_alt_rounded,
                    size: 18,
                    color: !p.isCompleted ? scheme.outline : (p.isOnTime ? athar.success : athar.warning),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.prayerName.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      color: p.isCompleted ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
