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

  /// The decoded error body — e.g. a `reason` or `retry_after` the caller can
  /// act on. Empty when the server sent none.
  final Map<String, dynamic> data;

  /// Machine-readable `reason` from the error body, if any.
  String? get reason => data['reason']?.toString();

  ApiException(this.message, {this.status, this.data = const {}});
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
    throw ApiException(data['message']?.toString() ?? 'Request failed', status: res.statusCode, data: data);
  }

  // --- Forgot password (public) ---

  /// Emails a 6-digit reset code. The server answers the same way whether or
  /// not the address is registered.
  Future<Map<String, dynamic>> forgotPassword(String email) async =>
      _unwrap(await _dio.post(ApiEndpoints.passwordForgot, data: {'email': email}));

  /// Checks a code without using it up (wrong guesses still count).
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async =>
      _unwrap(await _dio.post(ApiEndpoints.passwordVerify, data: {'email': email, 'code': code}));

  /// Sets the new password; signs the account out everywhere.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String confirmation,
  }) async =>
      _unwrap(await _dio.post(ApiEndpoints.passwordReset, data: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': confirmation,
      }));

  // --- Quran Werd ---

  /// Mushaf config plus where the reader left off.
  Future<Map<String, dynamic>> quranWerd() async =>
      _unwrap(await _dio.get(ApiEndpoints.quranWerd));

  /// Claims today's reward for [page], read for [seconds]. The only reading
  /// call: sent once a day, when the reward is due. The server checks the
  /// daily limit and whether the page still owes points.
  Future<Map<String, dynamic>> quranPageComplete(int page, int seconds) async =>
      _unwrap(await _dio.post(ApiEndpoints.quranPageComplete, data: {'page': page, 'seconds': seconds}));

  /// Extra reading time on a page already counted as read — the reader stayed
  /// on it. Adds time only: no second read, no points.
  Future<Map<String, dynamic>> quranPageTime(int page, int seconds) async =>
      _unwrap(await _dio.post(ApiEndpoints.quranPageTime, data: {'page': page, 'seconds': seconds}));

  /// The "read by how you feel" index: sections, their feelings, and the
  /// passages for each, in both languages. Small enough to fetch whole.
  Future<Map<String, dynamic>> quranMoods() async =>
      _unwrap(await _dio.get(ApiEndpoints.quranMoods));

  /// Passages the AI suggested for a category picked from the list, waiting
  /// for an admin's review — a category whose passages are those suggestions
  /// (possibly none). Slow when the AI is asked, so it waits longer than usual.
  Future<Map<String, dynamic>> quranMoodSuggestions(String categoryId, {CancelToken? cancelToken}) async =>
      _unwrap(await _dio.post(
        ApiEndpoints.quranMoodSuggestions,
        data: {'category_id': categoryId},
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      ));

  /// "Find passages by feeling". The body is one bilingual category; the rest
  /// arrives in headers — whether urgent safety guidance leads it, and whether
  /// passages suited to what was written can be asked for next. Generation can take a while, so this
  /// waits longer than usual; [cancelToken] lets the screen abandon it.
  Future<({Map<String, dynamic> category, bool generated, bool urgent, bool personal})> quranFeeling(
    String feeling,
    String locale, {
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.quranFeelings,
      data: {'feeling': feeling, 'locale': locale},
      cancelToken: cancelToken,
      options: Options(receiveTimeout: const Duration(seconds: 75)),
    );
    final category = await _unwrap(res);
    return (
      category: category,
      // Written for this feeling, rather than a saved category.
      generated: res.headers.value('x-quran-feeling-source') == 'generated',
      urgent: res.headers.value('x-quran-feeling-safety') == 'urgent',
      // A saved category, so passages suited to what was written can follow.
      personal: res.headers.value('x-quran-feeling-personal') == '1',
    );
  }

  /// Passages suited to what was written, beyond the general category already
  /// shown ([categoryId]). Nothing is saved for the person. Slow, since it
  /// asks the model, so it waits longer than usual.
  Future<Map<String, dynamic>> quranFeelingPersonal(
    String feeling,
    String categoryId,
    String locale, {
    CancelToken? cancelToken,
  }) async =>
      _unwrap(await _dio.post(
        ApiEndpoints.quranFeelingPersonal,
        data: {'feeling': feeling, 'category_id': categoryId, 'locale': locale},
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      ));


  // --- Dhikr ---

  /// Today's tasbeeh / istighfar counters, as the server sees them.
  Future<Map<String, dynamic>> dhikrToday(String timezone) async =>
      _unwrap(await _dio.get(ApiEndpoints.dhikrToday, queryParameters: {'timezone': timezone}));

  /// Reports [increments] taps since the last sync. The server owns the running
  /// total and is the only thing that decides whether the daily reward is due,
  /// so a retried call can never award the points twice.
  /// [date] is only sent when flushing a count finished before the day rolled
  /// over; the server accepts today or yesterday and rejects anything older.
  Future<Map<String, dynamic>> dhikrIncrement({
    required String dhikr,
    required int increments,
    required String timezone,
    String? date,
  }) async =>
      _unwrap(await _dio.post(ApiEndpoints.dhikrIncrement, data: {
        'dhikr': dhikr,
        'increments': increments,
        'timezone': timezone,
        if (date != null) 'dhikr_date': date,
      }));

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

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    int? age,
    String? email,
    String? gender,
  }) async =>
      _unwrap(await _dio.post('/profile', data: {
        if (name != null)   'name':   name,
        if (age != null)    'age':    age,
        if (email != null)  'email':  email,
        if (gender != null) 'gender': gender,
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

  /// Pins the device's IANA timezone server-side. Rate-limited to once a day
  /// by the API (429), so the server — not the device — owns "what time is it
  /// for this user".
  Future<Map<String, dynamic>> updateTimezone(String timezone) async =>
      _unwrap(await _dio.post(ApiEndpoints.timezone, data: {'timezone': timezone}));

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
        String? place,
        String? congregation,
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
            // The device's own "now" — the server compares it against real
            // time in the user's pinned timezone to detect a shifted clock.
            'client_time':  DateTime.now().toUtc().toIso8601String(),
            if (tz != null)                          'timezone':    tz,
            if (prayerDate != null)                  'prayer_date': prayerDate,
            if (prayerTime != null)                  'prayer_time': prayerTime,
            if (difficulty != null)                  'difficulty':  difficulty,
            if (mood != null)                        'mood':        mood,
            'place':        ?place,
            'congregation': ?congregation,
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

  Future<Map<String, dynamic>> statsInsights(String tz) async =>
      _unwrap(await _dio.get(ApiEndpoints.statsInsights, queryParameters: {'timezone': tz}));

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

  // --- Legal (public, no auth required) ---
  Future<Map<String, dynamic>> legalTerms() async => _unwrap(await _dio.get(ApiEndpoints.legalTerms));

  Future<Map<String, dynamic>> legalPrivacy() async => _unwrap(await _dio.get(ApiEndpoints.legalPrivacy));
}
