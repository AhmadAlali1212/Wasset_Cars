import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/rating_data.dart';
import 'package:mators_car/services/api_exception.dart';

// خدمة التقييمات — GET/POST /users/{user}/ratings
class RatingService {
  final RatingData _data = RatingData();

  Future<List<Map<String, dynamic>>> getRatings(int userId) async {
    final response = await _data.getRatings(userId);
    _handleResponseErrors(response, 'جلب التقييمات');
    return _normalizeList(response.data);
  }

  // ⬅️ جديد: المعاملات المكتملة التي يحق لي تقييمها الآن ولم أقيّمها بعد
  // (بيع مباع / مزاد مكتمل / حجز تأجير مكتمل). التقييم أصبح مربوطاً
  // بشكل صارم بمعاملة فعلية، فلم يعد هناك زر "قيّم" عام بلا سياق.
  Future<List<Map<String, dynamic>>> getRatableTransactions() async {
    final response = await _data.getRatableTransactions();
    _handleResponseErrors(response, 'جلب المعاملات القابلة للتقييم');
    final data = response.data;
    List list = [];
    if (data is Map && data['ratable'] is List) {
      list = data['ratable'] as List;
    }
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // من 1 إلى 5. يجب تمرير نوع المعاملة الفعلية ومعرّفها — السيرفر يرفض
  // أي تقييم لا يشير لمعاملة حقيقية مكتملة بين المُقيِّم والمُقيَّم.
  Future<void> addRating({
    required int userId,
    required int rating,
    String? comment,
    required String type, // 'ad' | 'auction' | 'rental_booking'
    required int transactionId,
  }) async {
    final response = await _data.addRating(
      userId: userId,
      rating: rating,
      comment: comment,
      type: type,
      transactionId: transactionId,
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
