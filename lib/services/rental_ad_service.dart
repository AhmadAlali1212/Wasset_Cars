import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../ulits/constans.dart';

/// خدمة إدارة إعلانات التأجير (Rental Ads)
/// تُغطي جميع نقاط API الموجودة ضمن قسم
/// "6. إدارة إعلانات التأجير (Rental Ads)" في ملف Postman:
/// - إنشاء إعلان تأجير (فردي/معرض)
/// - عرض جميع إعلانات التأجير مع بحث وفلترة
/// - عرض تفاصيل إعلان تأجير محدد
/// - تحديث إعلان تأجير
/// - نشر إعلان تأجير
/// - حذف إعلان تأجير
class RentalAdService {
  final Dio _dio;

  RentalAdService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  // إنشاء إعلان تأجير جديد (يعمل لكل من الفرد والمعرض بنفس الطريقة،
  // الفرق الوحيد أن car_id يجب أن يخص السيارات المملوكة لصاحب الحساب)
  Future<Map<String, dynamic>> createRentalAd({
    required int carId,
    required double dailyPrice,
    double? monthlyPrice,
    String? rentalConditions,
  }) async {
    final response = await _dio.post(
      '/rental-ads',
      data: {
        'car_id': carId,
        'daily_price': dailyPrice,
        if (monthlyPrice != null) 'monthly_price': monthlyPrice,
        if (rentalConditions != null && rentalConditions.trim().isNotEmpty)
          'rental_conditions': rentalConditions.trim(),
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إنشاء إعلان التأجير');
    return _normalizeResponse(response.data);
  }

  // عرض جميع إعلانات التأجير المنشورة مع بحث وفلترة (متاحة للجميع)
  Future<List<Map<String, dynamic>>> getAllRentalAds({
    double? minDailyPrice,
    double? maxDailyPrice,
    String? location,
    double? userLat,
    double? userLng,
    double? radius,
  }) async {
    final response = await _dio.get(
      '/rental-ads',
      queryParameters: {
        if (minDailyPrice != null) 'min_daily_price': minDailyPrice,
        if (maxDailyPrice != null) 'max_daily_price': maxDailyPrice,
        if (location != null && location.isNotEmpty) 'location': location,
        if (userLat != null) 'user_lat': userLat,
        if (userLng != null) 'user_lng': userLng,
        if (radius != null) 'radius': radius,
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب إعلانات التأجير');
    return _normalizeAdsList(response.data);
  }

  // جلب إعلانات التأجير الخاصة بي فقط (بأي حالة: مسودة/بانتظار المراجعة/منشورة/مرفوضة)
  // يستخدم الآن Endpoint مخصص: GET /rental-ads/my
  Future<List<Map<String, dynamic>>> getMyRentalAds({String? status}) async {
    final response = await _dio.get(
      '/rental-ads/my',
      queryParameters: {if (status != null && status.isNotEmpty) 'status': status},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب إعلانات التأجير الخاصة بي');
    return _normalizeAdsList(response.data);
  }

  // عرض إعلان تأجير محدد لي بالتحديد (بأي حالة) عبر GET /rental-ads/my/{id}
  Future<Map<String, dynamic>> getMyRentalAdDetails(int rentalAdId) async {
    final response = await _dio.get(
      '/rental-ads/my/$rentalAdId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب تفاصيل إعلان التأجير');
    return _normalizeResponse(response.data);
  }

  // عرض تفاصيل إعلان تأجير محدد
  Future<Map<String, dynamic>> getRentalAdDetails(int rentalAdId) async {
    final response = await _dio.get(
      '/rental-ads/$rentalAdId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب تفاصيل إعلان التأجير');
    return _normalizeResponse(response.data);
  }

  // تحديث إعلان تأجير (السعر اليومي/الشهري وشروط التأجير)
  Future<Map<String, dynamic>> updateRentalAd({
    required int rentalAdId,
    double? dailyPrice,
    double? monthlyPrice,
    String? rentalConditions,
  }) async {
    final response = await _dio.put(
      '/rental-ads/$rentalAdId',
      data: {
        if (dailyPrice != null) 'daily_price': dailyPrice,
        if (monthlyPrice != null) 'monthly_price': monthlyPrice,
        if (rentalConditions != null) 'rental_conditions': rentalConditions.trim(),
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تحديث إعلان التأجير');
    return _normalizeResponse(response.data);
  }

  // نشر إعلان تأجير (بعد الموافقة عليه من الأدمن مثلاً)
  Future<void> publishRentalAd(int rentalAdId) async {
    final response = await _dio.post(
      '/rental-ads/$rentalAdId/publish',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'نشر إعلان التأجير');
  }

  // حذف إعلان تأجير
  Future<void> deleteRentalAd(int rentalAdId) async {
    final response = await _dio.delete(
      '/rental-ads/$rentalAdId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'حذف إعلان التأجير');
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  List<Map<String, dynamic>> _normalizeAdsList(dynamic data) {
    final list = _extractList(data);
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'rental_ads', 'items', 'results']) {
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
    if (data is Map && data['rental_ad'] is Map) {
      return Map<String, dynamic>.from(data['rental_ad'] as Map);
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
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: '$operation فشل: $message',
      error: '$operation فشل: $message',
    );
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
          if (values.isNotEmpty) {
            lines.add('$key: $values');
          }
        } else if (value is String && value.trim().isNotEmpty) {
          lines.add('$key: ${value.trim()}');
        }
      });
    } else if (errors is String && errors.trim().isNotEmpty) {
      lines.add(errors.trim());
    }

    if (lines.isNotEmpty) {
      return lines.join('\n');
    }

    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return 'حدث خطأ غير معروف';
  }
}
