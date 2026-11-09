import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/rental/rental_ad_data.dart';

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
  final RentalAdData _data = RentalAdData();

  // إنشاء إعلان تأجير جديد (يعمل لكل من الفرد والمعرض بنفس الطريقة،
  // الفرق الوحيد أن car_id يجب أن يخص السيارات المملوكة لصاحب الحساب)
  Future<Map<String, dynamic>> createRentalAd({
    required int carId,
    required double dailyPrice,
    double? monthlyPrice,
    String? rentalConditions,
  }) async {
    final response = await _data.createRentalAd(
      carId: carId,
      dailyPrice: dailyPrice,
      monthlyPrice: monthlyPrice,
      rentalConditions: rentalConditions,
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
    int? perPage,
    int? page,
  }) async {
    final response = await _data.getAllRentalAds(
      minDailyPrice: minDailyPrice,
      maxDailyPrice: maxDailyPrice,
      location: location,
      userLat: userLat,
      userLng: userLng,
      radius: radius,
      perPage: perPage,
      page: page,
    );
    _handleResponseErrors(response, 'جلب إعلانات التأجير');
    return _normalizeAdsList(response.data);
  }

  // ⬅️ جديد: نفس فكرة getAllAdsAcrossPages بخدمة إعلانات البيع — يجلب كل
  // صفحات إعلانات التأجير بدل الاكتفاء بأول 15 إعلاناً فقط بصمت.
  Future<List<Map<String, dynamic>>> getAllRentalAdsAcrossPages({
    double? minDailyPrice,
    double? maxDailyPrice,
    String? location,
  }) async {
    const perPage = 100;
    const maxPages = 20;
    final all = <Map<String, dynamic>>[];

    for (var page = 1; page <= maxPages; page++) {
      final batch = await getAllRentalAds(
        minDailyPrice: minDailyPrice,
        maxDailyPrice: maxDailyPrice,
        location: location,
        perPage: perPage,
        page: page,
      );
      all.addAll(batch);
      if (batch.length < perPage) break;
    }

    return all;
  }

  // جلب إعلانات التأجير الخاصة بي فقط (بأي حالة: مسودة/بانتظار المراجعة/منشورة/مرفوضة)
  // يستخدم الآن Endpoint مخصص: GET /rental-ads/my
  Future<List<Map<String, dynamic>>> getMyRentalAds({String? status}) async {
    final response = await _data.getMyRentalAds(status: status);
    _handleResponseErrors(response, 'جلب إعلانات التأجير الخاصة بي');
    return _normalizeAdsList(response.data);
  }

  // عرض إعلان تأجير محدد لي بالتحديد (بأي حالة) عبر GET /rental-ads/my/{id}
  Future<Map<String, dynamic>> getMyRentalAdDetails(int rentalAdId) async {
    final response = await _data.getMyRentalAdDetails(rentalAdId);
    _handleResponseErrors(response, 'جلب تفاصيل إعلان التأجير');
    return _normalizeResponse(response.data);
  }

  // عرض تفاصيل إعلان تأجير محدد
  Future<Map<String, dynamic>> getRentalAdDetails(int rentalAdId) async {
    final response = await _data.getRentalAdDetails(rentalAdId);
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
    final response = await _data.updateRentalAd(
      rentalAdId: rentalAdId,
      dailyPrice: dailyPrice,
      monthlyPrice: monthlyPrice,
      rentalConditions: rentalConditions,
    );
    _handleResponseErrors(response, 'تحديث إعلان التأجير');
    return _normalizeResponse(response.data);
  }

  // نشر إعلان تأجير (بعد الموافقة عليه من الأدمن مثلاً)
  Future<void> publishRentalAd(int rentalAdId) async {
    final response = await _data.publishRentalAd(rentalAdId);
    _handleResponseErrors(response, 'نشر إعلان التأجير');
  }

  // حذف إعلان تأجير
  Future<void> deleteRentalAd(int rentalAdId) async {
    final response = await _data.deleteRentalAd(rentalAdId);
    _handleResponseErrors(response, 'حذف إعلان التأجير');
  }

  // ⬅️ جديد: جلب الأيام غير المتاحة لإعلان تأجير (حجوزات مؤكدة + فترات
  // حجبها المالك يدوياً) — تُستخدم لتعطيل هذه الأيام في تقويم الحجز.
  Future<List<Map<String, dynamic>>> getUnavailableRanges(
    int rentalAdId,
  ) async {
    final response = await _data.getUnavailableRanges(rentalAdId);
    _handleResponseErrors(response, 'جلب أيام عدم التوفر');
    final data = response.data;
    if (data is Map && data['unavailable_ranges'] is List) {
      return List<Map<String, dynamic>>.from(
        (data['unavailable_ranges'] as List).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    }
    return [];
  }

  // ⬅️ جديد: مالك الإعلان يحجب فترة أيام (السيارة غير متاحة فيها للتأجير)
  Future<Map<String, dynamic>> addUnavailableDates({
    required int rentalAdId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final response = await _data.addUnavailableDates(
      rentalAdId: rentalAdId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );
    _handleResponseErrors(response, 'حجب أيام عدم التوفر');
    return _normalizeResponse(response.data);
  }

  // ⬅️ جديد: مالك الإعلان يلغي حجب فترة أيام سبق أن حجبها
  Future<void> removeUnavailableDates({
    required int rentalAdId,
    required int unavailabilityId,
  }) async {
    final response = await _data.removeUnavailableDates(
      rentalAdId: rentalAdId,
      unavailabilityId: unavailabilityId,
    );
    _handleResponseErrors(response, 'إلغاء حجب أيام عدم التوفر');
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
      // The rental endpoint uses the same response envelope as the sales
      // endpoint in some deployments (`ads`), while others return
      // `rental_ads` or camelCase `rentalAds`.
      for (final key in [
        'data',
        'ads',
        'rental_ads',
        'rentalAds',
        'items',
        'results',
      ]) {
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
