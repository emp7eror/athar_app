import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'adhkar_store.dart';

/// Whether the counters have reached the server. Quiet when they have.
class AdhkarSyncBadge extends StatelessWidget {
  const AdhkarSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<AdhkarStore>();
    return Obx(() {
      final (label, icon, tone) = switch (store.syncState.value) {
        AdhkarSyncState.synced => (
          'adhkar_sync_synced'.tr,
          Icons.cloud_done_rounded,
          AtharTone.neutral,
        ),
        AdhkarSyncState.pending => (
          'adhkar_sync_pending'.tr,
          Icons.cloud_upload_rounded,
          AtharTone.neutral,
        ),
        AdhkarSyncState.syncing => (
          'adhkar_sync_syncing'.tr,
          Icons.sync_rounded,
          AtharTone.neutral,
        ),
        AdhkarSyncState.offline => (
          'adhkar_sync_offline'.tr,
          Icons.cloud_off_rounded,
          AtharTone.warning,
        ),
        AdhkarSyncState.failed => (
          'adhkar_sync_failed'.tr,
          Icons.error_outline_rounded,
          AtharTone.danger,
        ),
      };
      return Semantics(
        liveRegion: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AtharRadius.pill),
          // Tapping retries at once instead of waiting for the next attempt.
          onTap: store.pendingOps.value > 0 ? store.sync : null,
          child: AtharBadge(label: label, icon: icon, tone: tone),
        ),
      );
    });
  }
}
