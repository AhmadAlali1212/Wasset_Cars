import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/ads_data.dart';

class AdsService {
  final AdsData _data = AdsData();

  // جلب إعلاناتي (إعلانات البيع الخاصة بي) مع إمكانية الفلترة حسب الحالة
  // status: active / pending / draft ... الخ (حسب postman: my-ads?status=pending)
  Future<List<Map<String, dynamic>>> getMyAds({String? status}) async {
    final response = await _data.getMyAds(status: status);
    _handleResponseErrors(response, 'جلب إعلاناتي');
    return _normalizeAdsList(response.data);
  }

  // عرض تفاصيل إعلان بيع لي بالتحديد (my-ads/{id})
  Future<Map<String, dynamic>> getMyAdDetails(int adId) async {
    final response = await _data.getMyAdDetails(adId);
    _handleResponseErrors(response, 'جلب تفاصيل الإعلان');
    return _normalizeResponse(response.data);
  }

  // عرض جميع إعلانات البيع المنشورة مع بحث وفلترة (عامة لكل المستخدمين)
  // userId: لجلب إعلانات صاحب حساب محدد فقط (مثلاً كل سيارات شركة معيّنة)
  // perPage: للتحكم بعدد النتائج بالصفحة (الحد الأقصى المسموح به 100)
  Future<List<Map<String, dynamic>>> getAllAds({
    String? status,
    double? minPrice,
    double? maxPrice,
    String? make,
    double? userLat,
    double? userLng,
    double? radius,
    int? userId,
    int? perPage,
    int? page,
  }) async {
    final response = await _data.getAllAds(
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      make: make,
      userLat: userLat,
      userLng: userLng,
      radius: radius,
      userId: userId,
      perPage: perPage,
      page: page,
    );
    _handleResponseErrors(response, 'جلب الإعلانات');
    return _normalizeAdsList(response.data);
  }

  // ⬅️ جديد: جلب كل صفحات الإعلانات النشطة دفعة واحدة (بدل الاكتفاء بأول
  // 15 إعلاناً فقط، وهو ما كان يجعل الشاشة الرئيسية والبحث بها يفوّتان أي
  // سيارة بعد أول صفحة بصمت). يتوقف تلقائياً عند آخر صفحة، مع سقف أمان
  // (20 صفحة) لتفادي حلقة لا نهائية إذا تغيّر شكل استجابة السيرفر.
  Future<List<Map<String, dynamic>>> getAllAdsAcrossPages({
    String? status,
    double? minPrice,
    double? maxPrice,
    String? make,
    int? userId,
  }) async {
    const perPage = 100;
    const maxPages = 20;
    final all = <Map<String, dynamic>>[];

    for (var page = 1; page <= maxPages; page++) {
      final batch = await getAllAds(
        status: status,
        minPrice: minPrice,
        maxPrice: maxPrice,
        make: make,
        userId: userId,
        perPage: perPage,
        page: page,
      );
      all.addAll(batch);
      if (batch.length < perPage) break; // وصلنا لآخر صفحة
    }

    return all;
  }

  // عرض تفاصيل إعلان بيع محدد (متاح للجميع)
  Future<Map<String, dynamic>> getAdDetails(int adId) async {
    final response = await _data.getAdDetails(adId);
    _handleResponseErrors(response, 'جلب تفاصيل الإعلان');
    return _normalizeResponse(response.data);
  }

  // عرض إعلانات باقي المستخدمين (باستثناء إعلاناتي)
  Future<List<Map<String, dynamic>>> getOtherUsersAds() async {
    final response = await _data.getOtherUsersAds();
    _handleResponseErrors(response, 'جلب إعلانات المستخدمين الآخرين');
    return _normalizeAdsList(response.data);
  }

  Future<Map<String, dynamic>> createAd({
    required int carId,
    required double price,
  }) async {
    final response = await _data.createAd(carId: carId, price: price);
    _handleResponseErrors(response, 'إنشاء الإعلان');
    return _normalizeResponse(response.data);
  }

  // تحديث أسعار عدة إعلانات دفعة واحدة (مخصص للمعرض بعد الرفع الجماعي)
  // ads: كل عنصر عبارة عن {'ad_id': .., 'price': ..}
  Future<Map<String, dynamic>> bulkUpdatePrices(
    List<Map<String, dynamic>> ads,
  ) async {
    final response = await _data.bulkUpdatePrices(ads);
    _handleResponseErrors(response, 'تسعير الإعلانات دفعة واحدة');
    return _normalizeResponse(response.data);
  }

  Future<Map<String, dynamic>> updateAd({
    required int adId,
    required double price,
  }) async {
    final response = await _data.updateAd(adId: adId, price: price);
    _handleResponseErrors(response, 'تحديث الإعلان');
    return _normalizeResponse(response.data);
  }

  // تجديد إعلان بيع منتهي الصلاحية
  Future<Map<String, dynamic>> renewAd(
    int adId, {
    bool stillAvailable = true,
  }) async {
    final response = await _data.renewAd(adId, stillAvailable: stillAvailable);
    _handleResponseErrors(response, 'تجديد الإعلان');
    return _normalizeResponse(response.data);
  }

  Future<void> publishAd(int adId) async {
    final response = await _data.publishAd(adId);
    _handleResponseErrors(response, 'نشر الإعلان');
  }

  Future<void> deleteAd(int adId) async {
    final response = await _data.deleteAd(adId);
    _handleResponseErrors(response, 'حذف الإعلان');
  }

  // ⬅️ جديد: تعليم الإعلان "مباع" فعلياً (يحتفظ بالسجل بدل حذفه)، مع ربط
  // اختياري بالمشتري الفعلي لتفعيل نظام التقييم لاحقاً.
  Future<Map<String, dynamic>> markSold(int adId, {int? buyerId}) async {
    final response = await _data.markSold(adId, buyerId: buyerId);
    _handleResponseErrors(response, 'تعليم الإعلان كمباع');
    return _normalizeResponse(response.data);
  }

  List<Map<String, dynamic>> _normalizeAdsList(dynamic data) {
    final list = _extractList(data);
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // يبحث بعمق عن أول قائمة ضمن مفاتيح شائعة، بغض النظر عن عدد مستويات
  // التغليف (مثلاً {"ads": {"data": [...]}}) — يعالج ظهور نتائج فارغة رغم
  // وجود بيانات فعلية بسبب اختلاف شكل تغليف استجابة الـ API.
  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'ads', 'items', 'results']) {
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
    if (data is Map && data['ad'] is Map) {
      return Map<String, dynamic>.from(data['ad'] as Map);
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
