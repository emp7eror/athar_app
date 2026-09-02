import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/error_reporter.dart';

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
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async => _unwrap(await _dio.post(ApiEndpoints.register, data: body));

  Future<Map<String, dynamic>> login(String email, String password) async =>
      _unwrap(await _dio.post(ApiEndpoints.login, data: {'email': email, 'password': password}));

  /// Guest / "continue without account" login. Backend keys the user by
  /// [deviceId] so tapping this again on the same device returns the same
  /// user instead of creating a duplicate.
  Future<Map<String, dynamic>> anonymousLogin(String deviceId) async =>
      _unwrap(await _dio.post(ApiEndpoints.anonymousLogin, data: {'device_id': deviceId}));

  Future<void> logout() async => _dio.post(ApiEndpoints.logout);

  Future<Map<String, dynamic>> getProfile() async =>
      _unwrap(await _dio.get('/profile'));

  Future<Map<String, dynamic>> updateProfile({String? name, int? age}) async =>
      _unwrap(await _dio.post('/profile', data: {
        if (name != null) 'name': name,
        if (age != null)  'age':  age,
      }));

  Future<Map<String, dynamic>> updateAvatar(String filePath) async {
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
    });
    return _unwrap(await _dio.post('/profile/avatar', data: form));
  }

  Future<void> updateFcmToken(String token) async => _dio.post(ApiEndpoints.fcmToken, data: {'fcm_token': token});

  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async =>
      _unwrap(await _dio.post(ApiEndpoints.location, data: {'lat': lat, 'lng': lng}));

  // --- Prayers ---
  Future<Map<String, dynamic>> todayPrayers(String tz, {String? date}) async =>
      _unwrap(await _dio.get(ApiEndpoints.prayersToday, queryParameters: {
        'timezone': tz,
        if (date != null) 'date': date,
      }));

  /// Records a prayer as completed. Set [performedOutsideTime] = true (and
  /// pass a non-empty [reason]) for a *missed* prayer being logged after its
  /// scheduled window has closed. On-time completions leave those two null so
  /// the API contract stays unchanged.
  /// Records a prayer as completed. [prayerTime] carries the device-computed
  /// exact start time (ISO-8601) so the server can decide on-time-bonus
  /// eligibility from the same clock the client used, rather than recomputing
  /// prayer times from coordinates on the server.
  Future<Map<String, dynamic>> markPrayer(
      String prayer, {
        bool completed = true,
        String? tz,
        String? prayerDate,
        String? prayerTime,
        String? difficulty,
        String? mood,
        String? note,
        bool? performedOutsideTime,
        String? reason,
      }) async =>
      _unwrap(
        await _dio.post(
          ApiEndpoints.markPrayer,
          data: {
            'prayer_name':  prayer,
            'is_completed': completed,
            if (tz != null)                          'timezone':    tz,
            if (prayerDate != null)                  'prayer_date': prayerDate,
            if (prayerTime != null)                  'prayer_time': prayerTime,
            if (difficulty != null)                  'difficulty':  difficulty,
            if (mood != null)                        'mood':        mood,
            if (note != null && note.isNotEmpty)     'note':        note,
            if (performedOutsideTime == true)        'performed_outside_time': true,
            if (reason != null && reason.isNotEmpty) 'reason':      reason,
          },
        ),
      );

  // --- Friends ---
  Future<Map<String, dynamic>> friends() async => _unwrap(await _dio.get(ApiEndpoints.friends));

  Future<Map<String, dynamic>> addFriend(String code) async => _unwrap(await _dio.post(ApiEndpoints.addFriend, data: {'user_code': code}));

  Future<Map<String, dynamic>> addFriendById(int userId) async =>
      _unwrap(await _dio.post(ApiEndpoints.addFriendById, data: {'user_id': userId}));

  Future<Map<String, dynamic>> userProfile(int userId) async =>
      _unwrap(await _dio.get(ApiEndpoints.userProfile(userId)));

  Future<Map<String, dynamic>> respond(int friendshipId, String action) async =>
      _unwrap(await _dio.post(ApiEndpoints.respondFriend, data: {'friendship_id': friendshipId, 'action': action}));

  Future<void> nudge(int friendId) async => _dio.post(ApiEndpoints.nudge, data: {'friend_id': friendId});

  /// Remove an accepted friend. Backend should accept either the friendship id
  /// or the friend user id — we send both to be safe.
  Future<Map<String, dynamic>> removeFriend(int friendId) async =>
      _unwrap(await _dio.post(ApiEndpoints.removeFriend, data: {'friend_id': friendId}));

  // --- Analytics ---
  Future<Map<String, dynamic>> stats(String tz) async => _unwrap(await _dio.get(ApiEndpoints.stats, queryParameters: {'timezone': tz}));

  Future<Map<String, dynamic>> leaderboard({
    String tab = 'score',
    String scope = 'global',
    String period = 'current_month', // 'current_month' | 'all'
  }) async =>
      _unwrap(await _dio.get(ApiEndpoints.leaderboard, queryParameters: {
        'tab': tab,
        'scope': scope,
        'period': period,
      }));

  Future<Map<String, dynamic>> randomQuote() async => _unwrap(await _dio.get(ApiEndpoints.randomQuote));

  Future<void> logError({
    required String error,
    String? stack,
    String? platform,
    String? appVersion,
    String? device,
    String? route,
  }) async {
    try {
      await _dio.post('/errors/log', data: {
        'error':       error.length > 500 ? error.substring(0, 500) : error,
        'stack':        stack != null && stack.length > 5000
            ? stack.substring(0, 5000)
            : stack,
        'platform':    platform,
        'app_version': appVersion,
        'device':      device,
        'route':       route,
      });
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    }
  }
}
