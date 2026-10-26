import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ DisputeService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في DisputeService (services/controllers).
class DisputeData {
  final Dio _dio = DioClient.instance.dio;

  // POST /disputes
  Future<Response> raiseDispute({
    required int againstUserId,
    required String transactionType, // ad | auction | rental_booking
    required int transactionId,
    required String category,
    required String description,
  }) async {
    return _dio.post(
      '/disputes',
      data: {
        'against_user_id': againstUserId,
        'transaction_type': transactionType,
        'transaction_id': transactionId,
        'category': category,
        'description': description,
      },
      options: await _authOptions(),
    );
  }

  // GET /disputes/my
  Future<Response> getMyDisputes() async {
    return _dio.get(
      '/disputes/my',
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
