import 'dart:ui';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationController extends GetxController {
  final _box = GetStorage();
  static const _key = 'lang';
  final currentLang = 'ar'.obs;

  @override
  void onInit() {
    super.onInit();
    currentLang.value = _box.read(_key) ?? 'ar';
  }

  String get current => currentLang.value;
  bool get isRtl => current == 'ar';

  Locale get locale => Locale(current);

  void setLanguage(String code) {
    _box.write(_key, code);
    currentLang.value = code;
    Get.updateLocale(Locale(code)); // swaps text + layout direction instantly
  }

  void toggle() => setLanguage(current == 'ar' ? 'en' : 'ar');
}
