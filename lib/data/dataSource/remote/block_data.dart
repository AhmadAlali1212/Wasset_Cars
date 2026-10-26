import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ BlockService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في BlockService (services/controllers).
class BlockData {
  final Dio _dio = DioClient.instance.dio;

  // POST /blocks
  Future<Response> block(int userId) async {
    return _dio.post(
      '/blocks',
      data: {'blocked_user_id': userId},
      options: await _authOptions(),
    );
  }

  // DELETE /blocks/$userId
  Future<Response> unblock(int userId) async {
    return _dio.delete(
      '/blocks/$userId',
      options: await _authOptions(),
    );
  }

  // GET /blocks
  Future<Response> getMyBlockedUsers() async {
    return _dio.get('/blocks', options: await _authOptions());
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}
