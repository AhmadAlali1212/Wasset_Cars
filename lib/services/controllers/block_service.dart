import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/block_data.dart';

/// حظر مستخدم — يمنع الرسائل الجديدة بالاتجاهين، بدون حذف المحادثة القديمة.
class BlockService {
  final BlockData _data = BlockData();

  Future<void> block(int userId) async {
    final response = await _data.block(userId);
    _handleResponseErrors(response, 'حظر المستخدم');
  }

  Future<void> unblock(int userId) async {
    final response = await _data.unblock(userId);
    _handleResponseErrors(response, 'إلغاء الحظر');
  }

  Future<List<Map<String, dynamic>>> getMyBlockedUsers() async {
    final response = await _data.getMyBlockedUsers();
    _handleResponseErrors(response, 'جلب قائمة المحظورين');
    final data = response.data;
    List list = [];
    if (data is Map && data['blocks'] is List) list = data['blocks'] as List;
    return List<Map<String, dynamic>>.from(
      list.map((e) => Map<String, dynamic>.from(e)),
    );
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
