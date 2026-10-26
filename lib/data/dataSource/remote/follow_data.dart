import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ FollowService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في FollowService (services/controllers).
class FollowData {
  final Dio _dio = DioClient.instance.dio;

  // POST /companies/$companyId/follow
  Future<Response> followCompany(int companyId) async {
    return _dio.post(
      '/companies/$companyId/follow',
      options: await _authOptions(),
    );
  }

  // DELETE /companies/$companyId/follow
  Future<Response> unfollowCompany(int companyId) async {
    return _dio.delete(
      '/companies/$companyId/follow',
      options: await _authOptions(),
    );
  }

  // GET /companies/$companyId/follow-status
  Future<Response> isFollowing(int companyId) async {
    return _dio.get(
      '/companies/$companyId/follow-status',
      options: await _authOptions(),
    );
  }

  // GET /my-following-companies
  Future<Response> getMyFollowingCompanies() async {
    return _dio.get(
      '/my-following-companies',
      options: await _authOptions(),
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
