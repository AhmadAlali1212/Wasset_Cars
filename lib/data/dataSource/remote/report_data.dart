import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ ReportService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في ReportService (services/controllers).
class ReportData {
  final Dio _dio = DioClient.instance.dio;

  // POST /reports
  Future<Response> report({
    required int reportedUserId,
    required String
    reason, // fraud | abuse | inappropriate_content | spam | other
    String? details,
    String?
    contextType, // message | ad | auction | rental_ad | rental_booking | rating
    int? contextId,
  }) async {
    return _dio.post(
      '/reports',
      data: {
        'reported_user_id': reportedUserId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
        if (contextType != null) 'context_type': contextType,
        if (contextId != null) 'context_id': contextId,
      },
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
