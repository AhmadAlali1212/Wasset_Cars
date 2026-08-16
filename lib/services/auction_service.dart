import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../ulits/constans.dart';
import 'api_exception.dart';

// خدمة المزادات والعربون — تطابق قسم "06 - المزادات والعربون" في Postman
class AuctionService {
  final Dio _dio;

  AuctionService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          validateStatus: (status) => true,
        ),
      );

  // قائمة المزادات (نشطة/كل المزادات حسب الفلاتر الافتراضية للسيرفر)
  // GET /auctions يعرض حالة "active" فقط افتراضياً حسب توثيق الـ API،
  // لذلك نمرر status صراحة لجلب حالات أخرى مثل "pending" أيضاً.
  Future<List<Map<String, dynamic>>> getAuctions({String? status}) async {
    final response = await _dio.get(
      '/auctions',
      queryParameters: status != null ? {'status': status} : null,
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب المزادات');
    return _normalizeList(response.data);
  }

  // عرض مزاد بالتفصيل — ملاحظة مهمة: GET /auctions/{id} بالباك اند يرفض
  // (404) أي مزاد لا تكون حالته active، حتى لو كان موجوداً فعلاً بعد
  // إغلاقه (closed) — فكانت الشاشة تفشل بصمت في كل مرة تحاول تحديث مزاد
  // مغلق. لذلك: نجرب المسار المباشر أولاً (أسرع للمزادات النشطة)، ولو
  // فشل نبحث عن نفس المزاد ضمن القائمة العامة (GET /auctions?status=...)
  // التي لا تفرض هذا القيد ونستطيع فلترتها بأي حالة.
  Future<Map<String, dynamic>> getAuctionDetails(int auctionId) async {
    try {
      final response = await _dio.get(
        '/auctions/$auctionId',
        options: await _authOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _normalizeResponse(response.data);
      }
    } catch (_) {
      // نتابع للبحث عبر القائمة العامة بدل الفشل الفوري
    }

    for (final status in ['closed', 'active', 'pending', 'cancelled']) {
      try {
        final list = await getAuctions(status: status);
        final match = list.firstWhere(
          (json) => int.tryParse('${json['id']}') == auctionId,
          orElse: () => const {},
        );
        if (match.isNotEmpty) return match;
      } catch (_) {
        // جرّب الحالة التالية
      }
    }

    throw Exception('تعذر جلب تفاصيل المزاد (قد يكون غير موجود).');
  }

  // إنشاء مزاد جديد على سيارة أملكها
  Future<Map<String, dynamic>> createAuction({
    required int carId,
    required double startingPrice,
    required int durationHours,
  }) async {
    final response = await _dio.post(
      '/auctions',
      data: {
        'car_id': carId,
        'starting_price': startingPrice,
        'duration_hours': durationHours,
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إنشاء المزاد');
    return _normalizeResponse(response.data);
  }

  // تعديل مزاد (قبل بدء المزايدات عادة)
  Future<Map<String, dynamic>> updateAuction({
    required int auctionId,
    required double startingPrice,
    required int durationHours,
  }) async {
    final response = await _dio.put(
      '/auctions/$auctionId',
      data: {
        'starting_price': startingPrice,
        'duration_hours': durationHours,
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تعديل المزاد');
    return _normalizeResponse(response.data);
  }

  // تقديم مزايدة + حجز العربون تلقائياً من المحفظة
  Future<Map<String, dynamic>> placeBid({
    required int auctionId,
    required double amount,
  }) async {
    final response = await _dio.post(
      '/auctions/$auctionId/bid',
      data: {'amount': amount},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تقديم المزايدة');
    return _normalizeResponse(response.data);
  }

  // إغلاق المزادات المنتهية يدوياً (غالباً للاستخدام الإداري/المجدول)
  Future<void> closeExpiredAuctions() async {
    final response = await _dio.post(
      '/auctions/close-expired',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إغلاق المزادات المنتهية');
  }

  // البائع يقبل السعر النهائي بعد انتهاء المزاد
  Future<Map<String, dynamic>> acceptFinalPrice(int auctionId) async {
    final response = await _dio.post(
      '/auctions/$auctionId/accept-final-price',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'قبول السعر النهائي');
    return _normalizeResponse(response.data);
  }

  // البائع يرفض السعر النهائي بعد انتهاء المزاد
  Future<Map<String, dynamic>> rejectFinalPrice(int auctionId) async {
    final response = await _dio.post(
      '/auctions/$auctionId/reject-final-price',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'رفض السعر النهائي');
    return _normalizeResponse(response.data);
  }

  // تأكيد إتمام عملية البيع بعد اللقاء خارج التطبيق
  Future<Map<String, dynamic>> completeSale(int auctionId) async {
    final response = await _dio.post(
      '/auctions/$auctionId/complete-sale',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تأكيد إتمام البيع');
    return _normalizeResponse(response.data);
  }

  // الفائز يتراجع عن الصفقة (قد يفقد العربون حسب سياسة السيرفر)
  Future<Map<String, dynamic>> winnerWithdraw(int auctionId) async {
    final response = await _dio.post(
      '/auctions/$auctionId/winner-withdraw',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'التراجع عن المزاد');
    return _normalizeResponse(response.data);
  }

  Future<void> deleteAuction(int auctionId) async {
    final response = await _dio.delete(
      '/auctions/$auctionId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'حذف المزاد');
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
      for (final key in ['data', 'auctions', 'items', 'results']) {
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
    if (data is Map && data['auction'] is Map) {
      return Map<String, dynamic>.from(data['auction'] as Map);
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
    throw ApiException(
      '$operation فشل: $message',
      statusCode: response.statusCode,
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
