import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/services/notification_router.dart';
import '../../core/services/notification_service.dart';
import '../../core/ui/athar_ui.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import 'adhkar_models.dart';
import 'adhkar_store.dart';

/// One reminder the reader set: a time of day, on or off — for one of their
/// collections (its notification opens it), or a general one that opens the
/// Adhkar & Duas page.
class AdhkarReminder {
  AdhkarReminder({
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.collectionUid,
    this.collectionName,
  });

  int hour;
  int minute;
  bool enabled;

  /// The collection's [AdhkarCollection.uid]; null for a general reminder.
  final String? collectionUid;

  /// Its name, kept for the notification so it reads right even before the
  /// content has loaded.
  String? collectionName;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'collection_uid': collectionUid,
    'collection_name': collectionName,
  };

  static AdhkarReminder? fromJson(Object? j) {
    if (j is! Map) return null;
    final h = (j['hour'] as num?)?.round();
    final m = (j['minute'] as num?)?.round();
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return AdhkarReminder(
      hour: h,
      minute: m,
      enabled: j['enabled'] != false,
      collectionUid: j['collection_uid'] as String?,
      collectionName: j['collection_name'] as String?,
    );
  }
}

/// Adhkar & Duas reminders at times the reader chooses — none by default.
///
/// Kept on the device and scheduled as daily repeating local notifications.
/// The whole set is rebuilt on every change and when the app returns to the
/// foreground, so a timezone change (travel) moves them to the new local
/// time. Notification permission is only asked for when a reminder is turned
/// on.
class AdhkarReminders extends GetxService {
  final _box = GetStorage();
  static const _key = 'adhkar_reminders';

  /// Ids far from the prayer schedule (200000+) and nudges (epoch seconds).
  static const _idBase = 300000;
  static const maxReminders = 20;

  final reminders = <AdhkarReminder>[].obs;

  @override
  void onInit() {
    super.onInit();
    final raw = _box.read(_key);
    if (raw is List) {
      reminders.assignAll(
        raw.map(AdhkarReminder.fromJson).whereType<AdhkarReminder>(),
      );
    }
  }

  NotificationService get _notif => Get.find<NotificationService>();

  /// The reminders of [collection], or every reminder when it is null.
  List<AdhkarReminder> forCollection(AdhkarCollection? collection) =>
      collection == null
      ? reminders.toList()
      : reminders.where((r) => r.collectionUid == collection.uid).toList();

  Future<void> _save() async {
    await _box.write(_key, reminders.map((r) => r.toJson()).toList());
    reminders.refresh();
  }

  /// Asks for permission when it's actually needed. False when refused.
  Future<bool> _ensurePermission() async {
    if (await _notif.isReady) return true;
    final granted = await _notif.requestPermission();
    return granted && await _notif.isReady;
  }

  Future<bool> add(TimeOfDay time, {AdhkarCollection? collection}) async {
    if (reminders.length >= maxReminders) return false;
    if (!await _ensurePermission()) {
      AppSnackbar.error('adhkar_reminders'.tr, 'adhkar_reminder_permission'.tr);
      return false;
    }
    reminders.add(
      AdhkarReminder(
        hour: time.hour,
        minute: time.minute,
        collectionUid: collection?.uid,
        collectionName: collection?.name,
      ),
    );
    await _save();
    await reschedule();
    return true;
  }

  Future<void> edit(AdhkarReminder r, TimeOfDay time) async {
    r
      ..hour = time.hour
      ..minute = time.minute;
    await _save();
    await reschedule();
  }

  Future<void> setEnabled(AdhkarReminder r, bool on) async {
    if (on && !await _ensurePermission()) {
      AppSnackbar.error('adhkar_reminders'.tr, 'adhkar_reminder_permission'.tr);
      return;
    }
    r.enabled = on;
    await _save();
    await reschedule();
  }

  Future<void> remove(AdhkarReminder r) async {
    reminders.remove(r);
    await _save();
    await reschedule();
  }

  /// A deleted collection takes its reminders with it.
  Future<void> removeForCollection(AdhkarCollection collection) async {
    final before = reminders.length;
    reminders.removeWhere((r) => r.collectionUid == collection.uid);
    if (reminders.length == before) return;
    await _save();
    await reschedule();
  }

  /// Rebuilds the whole set: cancels every id this feature may have used,
  /// then schedules the enabled reminders again — each titled with its
  /// collection's current name, and opening that collection when tapped.
  Future<void> reschedule() async {
    try {
      await _notif.cancelMany(_allIds);
      if (!await _notif.isReady) return;

      final store = Get.isRegistered<AdhkarStore>()
          ? Get.find<AdhkarStore>()
          : null;
      var renamed = false;
      for (var i = 0; i < reminders.length; i++) {
        final r = reminders[i];
        final uid = r.collectionUid;
        if (uid != null && store != null) {
          final name = store.findCollection(uid)?.name;
          if (name != null && name != r.collectionName) {
            r.collectionName = name;
            renamed = true;
          }
        }
        if (!r.enabled) continue;

        final name = r.collectionName;
        await _notif.scheduleDaily(
          id: _idBase + i,
          hour: r.hour,
          minute: r.minute,
          title: name ?? 'adhkar_reminder_title'.tr,
          body: name == null
              ? 'adhkar_reminder_body'.tr
              : 'adhkar_reminder_body_for'.trParams({'name': name}),
          payload: NotificationRouter.adhkarPayloadFor(uid),
        );
      }
      if (renamed) await _save();
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    }
  }

  List<int> get _allIds => [for (var i = 0; i < maxReminders; i++) _idBase + i];

  /// Removes every reminder notification (account deleted).
  Future<void> cancelAll() => _notif.cancelMany(_allIds);
}

/// Lists, adds, edits and removes reminder times — for one collection when
/// [collection] is given, otherwise all of them (each with its collection).
class AdhkarRemindersSheet extends StatelessWidget {
  const AdhkarRemindersSheet({super.key, this.collection});

  final AdhkarCollection? collection;

  static Future<void> show(
    BuildContext context, {
    AdhkarCollection? collection,
  }) => showAtharSheet<void>(
    context: context,
    builder: (_) => AdhkarRemindersSheet(collection: collection),
  );

  Future<TimeOfDay?> _pick(BuildContext context, [TimeOfDay? initial]) =>
      showTimePicker(
        context: context,
        initialTime: initial ?? const TimeOfDay(hour: 7, minute: 0),
      );

  @override
  Widget build(BuildContext context) {
    final service = Get.find<AdhkarReminders>();
    final forOne = collection != null;
    return SafeArea(
      child: Obx(() {
        service.reminders.length;
        final list = service.forCollection(collection);
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AtharSpace.lg),
          children: [
            AtharSheetHeader(
              title: forOne
                  ? 'adhkar_reminders_for'.trParams({'name': collection!.name})
                  : 'adhkar_reminders'.tr,
              subtitle: forOne
                  ? 'adhkar_reminders_for_sub'.tr
                  : 'adhkar_reminders_sub'.tr,
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AtharSpace.lg,
                  vertical: AtharSpace.md,
                ),
                child: Text(
                  'adhkar_reminders_empty'.tr,
                  style: context.type.caption,
                  textAlign: TextAlign.center,
                ),
              )
            else
              AtharListGroup(
                children: [
                  for (final r in list)
                    AtharListRow(
                      icon: Icons.alarm_rounded,
                      title: r.time.format(context),
                      // All reminders: say which collection each opens.
                      subtitle: forOne
                          ? 'adhkar_reminder_daily'.tr
                          : (r.collectionName ?? 'adhkar_reminder_general'.tr),
                      onTap: () async {
                        final t = await _pick(context, r.time);
                        if (t != null) await service.edit(r, t);
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: r.enabled,
                            onChanged: (v) => service.setEnabled(r, v),
                          ),
                          AtharIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'adhkar_reminder_remove'.tr,
                            onPressed: () => service.remove(r),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: AtharSpace.md),
            // Reminders are added from inside a collection only; the list of
            // all of them can edit and delete, not add.
            if (forOne)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg),
                child: AtharButton(
                  label: 'adhkar_reminder_add'.tr,
                  icon: Icons.add_alarm_rounded,
                  expand: true,
                  onPressed:
                      service.reminders.length >= AdhkarReminders.maxReminders
                      ? null
                      : () async {
                          final t = await _pick(context);
                          if (t != null) {
                            await service.add(t, collection: collection);
                          }
                        },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AtharSpace.lg,
                  AtharSpace.sm,
                  AtharSpace.lg,
                  0,
                ),
                child: Text(
                  'adhkar_reminders_hint'.tr,
                  style: context.type.caption,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      }),
    );
  }
}
