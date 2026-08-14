import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../constants/api_endpoints.dart';
import 'api_interceptors.dart';

class DioClient extends GetxService {
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      validateStatus: (s) => s != null && s < 500,
    ))
      ..interceptors.add(ApiInterceptors());
  }
}
