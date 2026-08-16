import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../ulits/constans.dart';
import 'api_exception.dart';

// خدمة متابعة الشركات — تطابق قسم "12 - متابعة الشركات" بـ Postman
class FollowService {
  final Dio _dio;

  FollowService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          validateStatus: (status) => true,
        ),
      );

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> followCompany(int companyId) async {
    final response = await _dio.post(
      '/companies/$companyId/follow',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'متابعة الشركة');
  }

  Future<void> unfollowCompany(int companyId) async {
    final response = await _dio.delete(
      '/companies/$companyId/follow',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إلغاء متابعة الشركة');
  }

  // يُرجع true إذا كان المستخدم الحالي يتابع هذه الشركة
  Future<bool> isFollowing(int companyId) async {
    final response = await _dio.get(
      '/companies/$companyId/follow-status',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'التحقق من حالة المتابعة');
    final data = response.data;
    if (data is Map) {
      for (final key in ['is_following', 'following', 'status']) {
        final v = data[key];
        if (v == true || v?.toString().toLowerCase() == 'true') return true;
        if (v?.toString().toLowerCase() == 'following') return true;
      }
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getMyFollowingCompanies() async {
    final response = await _dio.get(
      '/my-following-companies',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب الشركات المتابَعة');
    return _normalizeList(response.data);
  }

  List<Map<String, dynamic>> _normalizeList(dynamic data) {
    dynamic list = data;
    if (list is Map) {
      list =
          list['companies'] ??
          list['following'] ??
          list['data'] ??
          list['items'] ??
          [];
    }
    if (list is Map && list['data'] is List) list = list['data'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) return;
    final message = _extractValidationMessage(response.data);
    throw ApiException(
      '$operation فشل: $message',
      statusCode: response.statusCode,
    );
  }

  String _extractValidationMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is! Map) return 'حدث خطأ غير معروف';
    if (data['message'] is String) return data['message'];
    if (data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final firstList = errors.values.isNotEmpty ? errors.values.first : null;
      if (firstList is List && firstList.isNotEmpty) {
        return firstList.first.toString();
      }
    }
    return 'حدث خطأ غير معروف';
  }
}
