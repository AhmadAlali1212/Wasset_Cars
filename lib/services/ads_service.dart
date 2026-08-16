import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../ulits/constans.dart';

class AdsService {
  final Dio _dio;

  AdsService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          // السماح باستلام كل الاستجابات (بما فيها 4xx) لعرض رسالة السيرفر
          // الحقيقية بدل رسالة DioException العامة.
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  // جلب إعلاناتي (إعلانات البيع الخاصة بي) مع إمكانية الفلترة حسب الحالة
  // status: active / pending / draft ... الخ (حسب postman: my-ads?status=pending)
  Future<List<Map<String, dynamic>>> getMyAds({String? status}) async {
    final response = await _dio.get(
      '/my-ads',
      queryParameters: {if (status != null && status.isNotEmpty) 'status': status},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب إعلاناتي');
    return _normalizeAdsList(response.data);
  }

  // عرض تفاصيل إعلان بيع لي بالتحديد (my-ads/{id})
  Future<Map<String, dynamic>> getMyAdDetails(int adId) async {
    final response = await _dio.get(
      '/my-ads/$adId',
      options: await _authOptions(),
    );
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
  }) async {
    final response = await _dio.get(
      '/ads',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (make != null && make.isNotEmpty) 'make': make,
        if (userLat != null) 'user_lat': userLat,
        if (userLng != null) 'user_lng': userLng,
        if (radius != null) 'radius': radius,
        if (userId != null) 'user_id': userId,
        if (perPage != null) 'per_page': perPage,
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب الإعلانات');
    return _normalizeAdsList(response.data);
  }

  // عرض تفاصيل إعلان بيع محدد (متاح للجميع)
  Future<Map<String, dynamic>> getAdDetails(int adId) async {
    final response = await _dio.get(
      '/ads/$adId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب تفاصيل الإعلان');
    return _normalizeResponse(response.data);
  }

  // عرض إعلانات باقي المستخدمين (باستثناء إعلاناتي)
  Future<List<Map<String, dynamic>>> getOtherUsersAds() async {
    final response = await _dio.get(
      '/other-users-ads',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب إعلانات المستخدمين الآخرين');
    return _normalizeAdsList(response.data);
  }

  Future<Map<String, dynamic>> createAd({
    required int carId,
    required double price,
  }) async {
    final response = await _dio.post(
      '/ads',
      data: {'car_id': carId, 'price': price},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إنشاء الإعلان');
    return _normalizeResponse(response.data);
  }

  // تحديث أسعار عدة إعلانات دفعة واحدة (مخصص للمعرض بعد الرفع الجماعي)
  // ads: كل عنصر عبارة عن {'ad_id': .., 'price': ..}
  Future<Map<String, dynamic>> bulkUpdatePrices(
    List<Map<String, dynamic>> ads,
  ) async {
    final response = await _dio.put(
      '/ads/bulk-publish',
      data: {'ads': ads},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تسعير الإعلانات دفعة واحدة');
    return _normalizeResponse(response.data);
  }

  Future<Map<String, dynamic>> updateAd({
    required int adId,
    required double price,
  }) async {
    final response = await _dio.put(
      '/my-ads/$adId',
      data: {'price': price},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تحديث الإعلان');
    return _normalizeResponse(response.data);
  }

  // تجديد إعلان بيع منتهي الصلاحية
  Future<Map<String, dynamic>> renewAd(
    int adId, {
    bool stillAvailable = true,
  }) async {
    final response = await _dio.post(
      '/my-ads/$adId/renew',
      data: {'still_available': stillAvailable},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تجديد الإعلان');
    return _normalizeResponse(response.data);
  }

  Future<void> publishAd(int adId) async {
    final response = await _dio.post(
      '/my-ads/$adId/publish',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'نشر الإعلان');
  }

  Future<void> deleteAd(int adId) async {
    final response = await _dio.delete(
      '/my-ads/$adId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'حذف الإعلان');
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
