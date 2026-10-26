import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/rental/rental_booking_data.dart';

// خدمة حجوزات التأجير — تطابق قسم "05 - حجوزات التأجير" في Postman
class RentalBookingService {
  final RentalBookingData _data = RentalBookingData();

  // إنشاء حجز تأجير جديد على إعلان تأجير منشور
  Future<Map<String, dynamic>> createBooking({
    required int rentalAdId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _data.createBooking(
      rentalAdId: rentalAdId,
      startDate: startDate,
      endDate: endDate,
    );
    _handleResponseErrors(response, 'إنشاء الحجز');
    return _normalizeResponse(response.data);
  }

  // جلب حجوزاتي (كمستأجر)
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final response = await _data.getMyBookings();
    _handleResponseErrors(response, 'جلب حجوزاتي');
    return _normalizeList(response.data);
  }

  // إلغاء حجز
  Future<void> cancelBooking(int bookingId) async {
    final response = await _data.cancelBooking(bookingId);
    _handleResponseErrors(response, 'إلغاء الحجز');
  }

  // ⬅️ جديد: الطلبات الواردة على إعلانات التأجير الخاصة بي (كمالك) —
  // كانت هذه الميزة مفقودة تماماً من الباك-إند سابقاً.
  Future<List<Map<String, dynamic>>> getIncomingBookings({
    String? status,
  }) async {
    final response = await _data.getIncomingBookings(status: status);
    _handleResponseErrors(response, 'جلب الطلبات الواردة');
    return _normalizeList(response.data);
  }

  // ⬅️ جديد: موافقة المالك على طلب حجز
  Future<void> approveBooking(int bookingId) async {
    final response = await _data.approveBooking(bookingId);
    _handleResponseErrors(response, 'الموافقة على الحجز');
  }

  // ⬅️ جديد: رفض المالك لطلب حجز
  Future<void> rejectBooking(int bookingId, {String? reason}) async {
    final response = await _data.rejectBooking(bookingId, reason: reason);
    _handleResponseErrors(response, 'رفض الحجز');
  }

  // ⬅️ جديد: تأكيد "تم التسليم" — يستبدل الحل المحلي المؤقت السابق
  Future<void> markDelivered(int bookingId) async {
    final response = await _data.markDelivered(bookingId);
    _handleResponseErrors(response, 'تأكيد التسليم');
  }

  // ⬅️ جديد: تأكيد "تم الإرجاع"
  Future<void> markReturned(int bookingId) async {
    final response = await _data.markReturned(bookingId);
    _handleResponseErrors(response, 'تأكيد الإرجاع');
  }

  List<Map<String, dynamic>> _normalizeList(dynamic data) {
    final list = _extractList(data);
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'bookings', 'items', 'results']) {
        final value = data[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return [];
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map && data['booking'] is Map) {
      return Map<String, dynamic>.from(data['booking'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    final message = _extractValidationMessage(response.data);
    throw Exception('$operation فشل: $message');
  }

  String _extractValidationMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is! Map) {
      return 'حدث خطأ غير معروف';
    }

    final map = Map<String, dynamic>.from(data);
    final errors = map['errors'];
    final lines = <String>[];

    if (errors is Map && errors.isNotEmpty) {
      errors.forEach((key, value) {
        if (value is List) {
          final values = value.map((item) => item.toString()).join(', ');
          if (values.isNotEmpty) lines.add('$key: $values');
        } else if (value is String && value.trim().isNotEmpty) {
          lines.add('$key: ${value.trim()}');
        }
      });
    } else if (errors is String && errors.trim().isNotEmpty) {
      lines.add(errors.trim());
    }

    if (lines.isNotEmpty) return lines.join('\n');

    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'حدث خطأ غير معروف';
  }
}
