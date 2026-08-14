import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Key-value persistence for JWT, coordinates, language, and cached user.
class StorageProvider extends GetxService {
  final _box = GetStorage();

  static const _kToken = 'token';
  static const _kLat = 'lat';
  static const _kLng = 'lng';
  static const _kCityAr = 'cityAr';
  static const _kCityEn = 'cityEn';
  static const _kUser = 'user';
  static const _kSeenOnboarding = 'seen_onboarding';
  static const _kDarkMode = 'dark_mode';

  String? get token => _box.read(_kToken);
  set token(String? v) => v == null ? _box.remove(_kToken) : _box.write(_kToken, v);

  bool get seenOnboarding => _box.read(_kSeenOnboarding) ?? false;
  set seenOnboarding(bool v) => _box.write(_kSeenOnboarding, v);

  bool get darkMode => _box.read(_kDarkMode) ?? false;
  set darkMode(bool v) => _box.write(_kDarkMode, v);

  double? get lat => _box.read(_kLat);
  double? get lng => _box.read(_kLng);
  String? get cityAr => _box.read(_kCityAr);
  String? get cityEn => _box.read(_kCityEn);

  void saveCoords(double lat, double lng) {
    _box.write(_kLat, lat);
    _box.write(_kLng, lng);
  }

  void saveCity(String? nameAr, String? nameEn) {
    if (nameAr != null) _box.write(_kCityAr, nameAr);
    if (nameEn != null) _box.write(_kCityEn, nameEn);
  }

  Map<String, dynamic>? get cachedUser => _box.read(_kUser);
  set cachedUser(Map<String, dynamic>? v) =>
      v == null ? _box.remove(_kUser) : _box.write(_kUser, v);

  bool get isLoggedIn => (token ?? '').isNotEmpty;

  void clear() {
    _box.remove(_kToken);
    _box.remove(_kUser);
  }
}
