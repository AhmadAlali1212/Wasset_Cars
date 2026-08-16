import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../ulits/constans.dart';

// خدمة حجوزات التأجير — تطابق قسم "05 - حجوزات التأجير" في Postman
class RentalBookingService {
  final Dio _dio;

  RentalBookingService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  // إنشاء حجز تأجير جديد على إعلان تأجير منشور
  Future<Map<String, dynamic>> createBooking({
    required int rentalAdId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.post(
      '/rental-bookings',
      data: {
        'rental_ad_id': rentalAdId,
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إنشاء الحجز');
    return _normalizeResponse(response.data);
  }

  // جلب حجوزاتي (كمستأجر)
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final response = await _dio.get(
      '/rental-bookings/my',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب حجوزاتي');
    return _normalizeList(response.data);
  }

  // إلغاء حجز
  Future<void> cancelBooking(int bookingId) async {
    final response = await _dio.delete(
      '/rental-bookings/$bookingId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إلغاء الحجز');
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
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
