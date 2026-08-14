import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../data/providers/storage_provider.dart';
import '../localization/localization_controller.dart';

/// Injects the Sanctum bearer token and the Accept-Language header on every
/// request, and clears the session on a 401.
class ApiInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final storage = Get.find<StorageProvider>();
    final lang = Get.isRegistered<LocalizationController>()
        ? Get.find<LocalizationController>().current
        : 'ar';

    final token = storage.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Accept-Language'] = lang;

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      Get.find<StorageProvider>().clear();
      Get.offAllNamed('/auth');
    }
    handler.next(err);
  }
}
