import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/adhan_service.dart';
import '../../core/ui/athar_ui.dart';
import '../home/home_controller.dart';

/// The settings row for how prayer times are calculated: the method (the
/// Fajr/Isha angles of a known authority) and the madhab for Asr.
class PrayerCalculationRow extends StatefulWidget {
  const PrayerCalculationRow({super.key});

  @override
  State<PrayerCalculationRow> createState() => _PrayerCalculationRowState();
}

class _PrayerCalculationRowState extends State<PrayerCalculationRow> {
  final _adhan = Get.find<AdhanService>();

  @override
  Widget build(BuildContext context) {
    return AtharListRow(
      icon: Icons.calculate_rounded,
      title: 'prayer_calc_method'.tr,
      subtitle: '${methodLabel(_adhan.method)} · ${madhabLabel(_adhan.madhab)}',
      onTap: () async {
        await PrayerCalculationSheet.show(context);
        if (mounted) setState(() {});
      },
    );
  }
}

String methodLabel(CalculationMethod m) => 'calc_${m.name}'.tr;

String madhabLabel(Madhab m) =>
    m == Madhab.hanafi ? 'madhab_hanafi'.tr : 'madhab_shafi'.tr;

class PrayerCalculationSheet extends StatefulWidget {
  const PrayerCalculationSheet({super.key});

  static Future<void> show(BuildContext context) => showAtharSheet<void>(
    context: context,
    builder: (_) => const PrayerCalculationSheet(),
  );

  @override
  State<PrayerCalculationSheet> createState() => _PrayerCalculationSheetState();
}

class _PrayerCalculationSheetState extends State<PrayerCalculationSheet> {
  final _adhan = Get.find<AdhanService>();

  Future<void> _apply({CalculationMethod? method, Madhab? madhab}) async {
    await _adhan.setCalculation(method: method, madhab: madhab);
    if (mounted) setState(() {});
    // Same as a new location: the times on Home and every scheduled reminder
    // were computed with the old settings.
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().onLocationChanged();
    }
  }

  Widget _check(bool selected) {
    final scheme = context.colors;
    return Icon(
      selected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      size: AtharSize.iconLg,
      color: selected ? scheme.primary : scheme.outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final method = _adhan.method;
    final madhab = _adhan.madhab;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AtharSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtharSheetHeader(
              title: 'prayer_calc_method'.tr,
              subtitle: 'prayer_calc_method_sub'.tr,
            ),
            AtharListGroup(
              title: 'asr_madhab'.tr,
              children: [
                for (final m in const [Madhab.shafi, Madhab.hanafi])
                  AtharListRow(
                    icon: Icons.wb_sunny_rounded,
                    title: madhabLabel(m),
                    trailing: _check(m == madhab),
                    onTap: m == madhab ? null : () => _apply(madhab: m),
                  ),
              ],
            ),
            const SizedBox(height: AtharSpace.lg),
            AtharListGroup(
              title: 'prayer_calc_method'.tr,
              children: [
                for (final m in AdhanService.methods)
                  AtharListRow(
                    icon: Icons.mosque_rounded,
                    title: methodLabel(m),
                    trailing: _check(m == method),
                    onTap: m == method ? null : () => _apply(method: m),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
