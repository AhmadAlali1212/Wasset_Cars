import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ UserSearchService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في UserSearchService (services/controllers).
class UserSearchData {
  final Dio _dio = DioClient.instance.dio;

  // GET /users/search
  Future<Response> search(String query) async {
    return _dio.get(
      '/users/search',
      queryParameters: {'q': query.trim()},
      options: await _authOptions(),
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
