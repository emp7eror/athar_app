import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';

/// Central typed access to the Laravel API. Returns decoded maps; controllers
/// map them into models. Throws [ApiException] on non-2xx for uniform handling.
class ApiException implements Exception {
  final int? status;
  final String message;
  ApiException(this.message, {this.status});
  @override
  String toString() => message;
}

class ApiProvider {
  Dio get _dio => Get.find<DioClient>().dio;

  Future<Map<String, dynamic>> _unwrap(Response res) async {
    final data = res.data is Map ? res.data as Map<String, dynamic> : <String, dynamic>{};
    if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Request failed', status: res.statusCode);
  }

  // --- Auth ---
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async =>
      _unwrap(await _dio.post(ApiEndpoints.register, data: body));

  Future<Map<String, dynamic>> login(String email, String password) async =>
      _unwrap(await _dio.post(ApiEndpoints.login, data: {'email': email, 'password': password}));

  Future<void> logout() async => _dio.post(ApiEndpoints.logout);

  Future<void> updateFcmToken(String token) async =>
      _dio.post(ApiEndpoints.fcmToken, data: {'fcm_token': token});

  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async =>
      _unwrap(await _dio.post(ApiEndpoints.location, data: {'lat': lat, 'lng': lng}));

  // --- Prayers ---
  Future<Map<String, dynamic>> todayPrayers(String tz) async =>
      _unwrap(await _dio.get(ApiEndpoints.prayersToday, queryParameters: {'timezone': tz}));

  Future<Map<String, dynamic>> markPrayer(String prayer, {bool completed = true, String? tz}) async =>
      _unwrap(await _dio.post(ApiEndpoints.markPrayer, data: {
        'prayer_name': prayer,
        'is_completed': completed,
        if (tz != null) 'timezone': tz,
      }));

  // --- Friends ---
  Future<Map<String, dynamic>> friends() async => _unwrap(await _dio.get(ApiEndpoints.friends));

  Future<Map<String, dynamic>> addFriend(String code) async =>
      _unwrap(await _dio.post(ApiEndpoints.addFriend, data: {'user_code': code}));

  Future<Map<String, dynamic>> respond(int friendshipId, String action) async =>
      _unwrap(await _dio.post(ApiEndpoints.respondFriend,
          data: {'friendship_id': friendshipId, 'action': action}));

  Future<void> nudge(int friendId) async =>
      _dio.post(ApiEndpoints.nudge, data: {'friend_id': friendId});

  // --- Analytics ---
  Future<Map<String, dynamic>> stats(String tz) async =>
      _unwrap(await _dio.get(ApiEndpoints.stats, queryParameters: {'timezone': tz}));

  Future<Map<String, dynamic>> leaderboard({String tab = 'points', String scope = 'global'}) async =>
      _unwrap(await _dio.get(ApiEndpoints.leaderboard, queryParameters: {'tab': tab, 'scope': scope}));

  Future<Map<String, dynamic>> randomQuote() async =>
      _unwrap(await _dio.get(ApiEndpoints.randomQuote));
}
