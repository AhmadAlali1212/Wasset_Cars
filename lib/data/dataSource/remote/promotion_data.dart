import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ PromotionService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في PromotionService (services/controllers).
class PromotionData {
  final Dio _dio = DioClient.instance.dio;

  // GET /promotions
  Future<Response> getPromotions() async {
    return _dio.get(
      '/promotions',
      options: await _authOptions(),
    );
  }

  // GET /promotions/$promotionId
  Future<Response> getPromotionDetails(int promotionId) async {
    return _dio.get(
      '/promotions/$promotionId',
      options: await _authOptions(),
    );
  }

  // POST /promotions
  Future<Response> createPromotion({
    required String title,
    required String description,
    required String type,
    required double value,
    required DateTime startDate,
    required DateTime endDate,
    required int quantity,
  }) async {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.post(
      '/promotions',
      data: {
        'title': title,
        'description': description,
        'type': type,
        'value': value,
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
        'quantity': quantity,
      },
      options: await _authOptions(),
    );
    return response;
  }

  // PUT /promotions/$promotionId
  Future<Response> updatePromotion({
    required int promotionId,
    required String title,
    required String description,
    required String type,
    required double value,
    required DateTime startDate,
    required DateTime endDate,
    required int quantity,
  }) async {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.put(
      '/promotions/$promotionId',
      data: {
        'title': title,
        'description': description,
        'type': type,
        'value': value,
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
        'quantity': quantity,
      },
      options: await _authOptions(),
    );
    return response;
  }

  // DELETE /promotions/$promotionId
  Future<Response> deletePromotion(int promotionId) async {
    return _dio.delete(
      '/promotions/$promotionId',
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
