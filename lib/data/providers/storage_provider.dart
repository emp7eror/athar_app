import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Key-value persistence for JWT, coordinates, language, and cached user.
class StorageProvider extends GetxService {
  final _box = GetStorage();

  static const _kToken = 'token';
  static const _kLat = 'lat';
  static const _kLng = 'lng';
  static const _kUser = 'user';

  String? get token => _box.read(_kToken);
  set token(String? v) => v == null ? _box.remove(_kToken) : _box.write(_kToken, v);

  double? get lat => _box.read(_kLat);
  double? get lng => _box.read(_kLng);
  void saveCoords(double lat, double lng) {
    _box.write(_kLat, lat);
    _box.write(_kLng, lng);
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
