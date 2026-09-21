import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/services/location_service.dart';
import '../core/ui/athar_ui.dart';
import '../data/providers/api_provider.dart';

/// Choosing where you are by name, when the device won't say.
///
/// Prayer times are calculated on the device from coordinates, so a city
/// picked here works exactly as well as a GPS reading — no location
/// permission involved. Opened from the permission gate and from
/// Settings → Location.
class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({super.key});

  /// Returns true when a city was chosen and saved.
  static Future<bool> show(BuildContext context) async =>
      await showAtharSheet<bool>(context: context, builder: (_) => const CityPickerSheet()) ?? false;

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final _input = TextEditingController();
  final _api = Get.find<ApiProvider>();

  Timer? _debounce;
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;
  bool _failed = false;
  String? _saving;

  /// The query the last request was made for, so a slow response for an old
  /// query can't overwrite the results of a newer one.
  String _pending = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
        _failed = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    _pending = query;
    try {
      final cities = await _api.searchCities(query);
      if (!mounted || _pending != query) return;
      setState(() {
        _results = cities;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted || _pending != query) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _choose(Map<String, dynamic> city) async {
    final name = city['name_en']?.toString() ?? '';
    setState(() => _saving = name);
    await Get.find<LocationService>().saveManualCity(
      lat: (city['latitude'] as num).toDouble(),
      lng: (city['longitude'] as num).toDouble(),
      nameAr: city['name_ar']?.toString(),
      nameEn: city['name_en']?.toString(),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    final query = _input.text.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtharSheetHeader(title: 'city_picker_title'.tr, subtitle: 'city_picker_sub'.tr),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg),
            child: TextField(
              controller: _input,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'city_picker_hint'.tr,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: AtharSpace.sm),
          SizedBox(
            height: 320,
            child: switch ((_loading, _failed, query.length, _results.isEmpty)) {
              (true, _, _, _) => const AtharLoadingState(),
              (_, true, _, _) => AtharErrorState(
                  message: 'city_picker_failed'.tr,
                  onRetry: () => _search(query),
                ),
              (_, _, < 2, _) => AtharEmptyState(
                  icon: Icons.travel_explore_rounded,
                  title: 'city_picker_prompt'.tr,
                ),
              (_, _, _, true) => AtharEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'city_picker_none'.tr,
                ),
              _ => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final city = _results[i];
                    final name = (isAr ? city['name_ar'] : city['name_en'])?.toString() ?? '';
                    final busy = _saving == city['name_en']?.toString();

                    return AtharListRow(
                      icon: Icons.location_city_rounded,
                      title: name.isEmpty ? (city['name_en']?.toString() ?? '') : name,
                      subtitle: city['country_code']?.toString(),
                      showChevron: false,
                      trailing: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: _saving != null ? null : () => _choose(city),
                    );
                  },
                ),
            },
          ),
          const SizedBox(height: AtharSpace.lg),
        ],
      ),
    );
  }
}
