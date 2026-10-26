import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/report_data.dart';

/// إبلاغ عن مستخدم — سدّ فجوة الأمان الحقيقية: النظام صار فيه رسائل
/// ومزادات وحجوزات حقيقية، بدون أي طريقة يبلّغ فيها مستخدم عن ثاني.
class ReportService {
  final ReportData _data = ReportData();

  Future<void> report({
    required int reportedUserId,
    required String
    reason, // fraud | abuse | inappropriate_content | spam | other
    String? details,
    String?
    contextType, // message | ad | auction | rental_ad | rental_booking | rating
    int? contextId,
  }) async {
    final response = await _data.report(
      reportedUserId: reportedUserId,
      reason: reason,
      details: details,
      contextType: contextType,
      contextId: contextId,
    );
    _handleResponseErrors(response, 'إرسال البلاغ');
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
