import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ NotificationService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في NotificationService (services/controllers).
class NotificationData {
  final Dio _dio = DioClient.instance.dio;

  // GET /notifications
  Future<Response> getNotifications({
    int page = 1,
    String? status,
  }) async {
    return _dio.get(
      '/notifications',
      queryParameters: {'page': page, if (status != null) 'status': status},
      options: await _authOptions(),
    );
  }

  // GET /notifications/$id
  Future<Response> getNotificationDetails(String id) async {
    return _dio.get(
      '/notifications/$id',
      options: await _authOptions(),
    );
  }

  // PATCH /notifications/$id/read
  Future<Response> markAsRead(String id) async {
    return _dio.patch(
      '/notifications/$id/read',
      options: await _authOptions(),
    );
  }

  // PATCH /notifications/read-all
  Future<Response> markAllAsRead() async {
    return _dio.patch(
      '/notifications/read-all',
      options: await _authOptions(),
    );
  }

  // DELETE /notifications/$id
  Future<Response> deleteNotification(String id) async {
    return _dio.delete(
      '/notifications/$id',
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
