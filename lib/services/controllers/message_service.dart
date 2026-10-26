import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/message_data.dart';

/// خدمة الرسائل الحقيقية داخل التطبيق — بديل عملي عن الاعتماد الكامل على
/// واتساب خارجي، خصوصاً للتواصل حول مزاد أو حجز أو إعلان معيّن.
class MessageService {
  final MessageData _data = MessageData();

  // قائمة المحادثات (آخر رسالة مع كل طرف + عدد غير المقروء)
  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await _data.getConversations();
    _handleResponseErrors(response, 'جلب المحادثات');
    final data = response.data;
    List list = [];
    if (data is Map && data['conversations'] is List) {
      list = data['conversations'] as List;
    }
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // الرسائل بيني وبين مستخدم معيّن
  Future<List<Map<String, dynamic>>> getThread(
    int partnerId, {
    int page = 1,
  }) async {
    final response = await _data.getThread(partnerId, page: page);
    _handleResponseErrors(response, 'جلب الرسائل');
    final data = response.data;
    List list = [];
    if (data is Map && data['messages'] is List) {
      list = data['messages'] as List;
    }
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // إرسال رسالة جديدة
  Future<Map<String, dynamic>> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    final response = await _data.sendMessage(
      receiverId: receiverId,
      content: content,
    );
    _handleResponseErrors(response, 'إرسال الرسالة');
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return {};
  }

  // عدد الرسائل غير المقروءة إجمالاً (لشارة برأس التطبيق لاحقاً)
  Future<int> getUnreadCount() async {
    final response = await _data.getUnreadCount();
    _handleResponseErrors(response, 'جلب عدد الرسائل غير المقروءة');
    final data = response.data;
    if (data is Map && data['unread_count'] is int) {
      return data['unread_count'] as int;
    }
    return 0;
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
