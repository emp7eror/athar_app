import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'profile_controller.dart';

/// Confirms erasing the account, and says plainly what goes with it.
///
/// Deletion is immediate and cannot be undone, so agreeing takes more than a
/// tap: the user types the confirmation word before the button comes alive.
/// No password is asked for — guest accounts have one they have never seen.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<void> show() => Get.dialog<void>(const DeleteAccountDialog());

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _input = TextEditingController();
  final _controller = Get.find<ProfileController>();

  /// Typed by the user to arm the button; localized so an Arabic reader isn't
  /// asked to type a Latin word.
  String get _keyword => 'delete_account_keyword'.tr;

  bool get _armed => _input.text.trim().toLowerCase() == _keyword.toLowerCase();

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    try {
      await _controller.deleteAccount();
    } catch (_) {
      // The controller has already told the user; keep the dialog open so
      // they can try again or back out.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final danger = AtharTone.danger;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AtharSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: danger.background(context), shape: BoxShape.circle),
                  child: Icon(Icons.delete_forever_rounded, size: 28, color: danger.foreground(context)),
                ),
              ),
              const SizedBox(height: AtharSpace.md),
              Semantics(
                header: true,
                child: Text('delete_account'.tr, textAlign: TextAlign.center, style: context.text.titleLarge),
              ),
              const SizedBox(height: AtharSpace.xs),
              Text(
                'delete_account_warning'.tr,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AtharSpace.md),
              AtharCard(
                tone: AtharCardTone.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final key in const [
                      'delete_account_item_prayers',
                      'delete_account_item_points',
                      'delete_account_item_quran',
                      'delete_account_item_friends',
                      'delete_account_item_profile',
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.remove_rounded, size: AtharSize.iconSm, color: scheme.onSurfaceVariant),
                            const SizedBox(width: AtharSpace.xs),
                            Expanded(child: Text(key.tr, style: context.text.bodySmall)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AtharSpace.md),
              Text(
                'delete_account_type_to_confirm'.trParams({'word': _keyword}),
                style: context.type.caption,
              ),
              const SizedBox(height: AtharSpace.xs),
              TextField(
                controller: _input,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(hintText: _keyword),
              ),
              const SizedBox(height: AtharSpace.lg),
              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AtharButton(
                      label: 'delete_account'.tr,
                      variant: AtharButtonVariant.danger,
                      expand: true,
                      loading: _controller.deleting.value,
                      onPressed: _armed && !_controller.deleting.value ? _delete : null,
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    AtharButton(
                      label: 'cancel'.tr,
                      variant: AtharButtonVariant.ghost,
                      expand: true,
                      onPressed: _controller.deleting.value ? null : () => Get.back<void>(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
