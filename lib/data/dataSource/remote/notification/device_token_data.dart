import 'package:dio/dio.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات رمز جهاز FCM الخام (POST/DELETE /device-tokens): تعيد الـ Response كما هو.
/// المنطق (التحقق من وجود التوكن، تجاهل الأخطاء) في PushNotificationService.
class DeviceTokenData {
  final Dio _dio = DioClient.instance.dio;

  // POST /device-tokens
  Future<Response> register({
    required String authToken,
    required String token,
    required String platform,
  }) async {
    return _dio.post(
      '/device-tokens',
      data: {'token': token, 'platform': platform},
      options: _authOptions(authToken),
    );
  }

  // DELETE /device-tokens
  Future<Response> unregister({
    required String authToken,
    required String token,
  }) async {
    return _dio.delete(
      '/device-tokens',
      data: {'token': token},
      options: _authOptions(authToken),
    );
  }

  Options _authOptions(String authToken) {
    return Options(
      headers: {'Authorization': 'Bearer $authToken', 'Accept': 'application/json'},
    );
  }
}
