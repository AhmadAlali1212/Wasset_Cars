import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../ulits/constans.dart';
import 'api_exception.dart';

// خدمة التقييمات — GET/POST /users/{user}/ratings
class RatingService {
  final Dio _dio;

  RatingService()
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

  Future<List<Map<String, dynamic>>> getRatings(int userId) async {
    final response = await _dio.get(
      '/users/$userId/ratings',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب التقييمات');
    return _normalizeList(response.data);
  }

  // من 1 إلى 5. لا يسمح السيرفر بتقييم النفس أو تكرار تقييم نفس المستخدم.
  Future<void> addRating({
    required int userId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post(
      '/users/$userId/ratings',
      data: {'rating': rating, if (comment != null) 'comment': comment},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إضافة التقييم');
  }

  List<Map<String, dynamic>> _normalizeList(dynamic data) {
    dynamic list = data;
    if (list is Map) {
      list = list['ratings'] ?? list['data'] ?? list['items'] ?? [];
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
