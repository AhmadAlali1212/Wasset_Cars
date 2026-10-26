import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ SubscriptionService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في SubscriptionService (services/controllers).
class SubscriptionData {
  final Dio _dio = DioClient.instance.dio;

  // GET /subscription
  Future<Response> getSubscriptionStatus() async {
    return _dio.get(
      '/subscription',
      options: await _authOptions(),
    );
  }

  // POST /subscription/subscribe
  Future<Response> subscribe() async {
    return _dio.post(
      '/subscription/subscribe',
      options: await _authOptions(),
    );
  }

  // POST /subscription/cancel
  Future<Response> cancelSubscription() async {
    return _dio.post(
      '/subscription/cancel',
      options: await _authOptions(),
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}
