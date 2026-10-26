import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/dispute_data.dart';

/// نظام نزاعات مرتبط بمعاملة فعلية — بديل حقيقي لعدم وجود آلية تصعيد
/// للأدمن عند مشاكل مثل "السيارة مو متل الوصف" أو "ما رجّع السيارة".
class DisputeService {
  final DisputeData _data = DisputeData();

  Future<void> raiseDispute({
    required int againstUserId,
    required String transactionType, // ad | auction | rental_booking
    required int transactionId,
    required String category,
    required String description,
  }) async {
    final response = await _data.raiseDispute(
      againstUserId: againstUserId,
      transactionType: transactionType,
      transactionId: transactionId,
      category: category,
      description: description,
    );
    _handleResponseErrors(response, 'رفع النزاع');
  }

  Future<List<Map<String, dynamic>>> getMyDisputes() async {
    final response = await _data.getMyDisputes();
    _handleResponseErrors(response, 'جلب نزاعاتي');
    final data = response.data;
    if (data is Map &&
        data['disputes'] is Map &&
        data['disputes']['data'] is List) {
      return List<Map<String, dynamic>>.from(
        (data['disputes']['data'] as List).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );
    }
    return [];
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return;
    }
    final data = response.data;
    String message = 'حدث خطأ غير معروف';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }
    throw Exception('$operation فشل: $message');
  }
}
