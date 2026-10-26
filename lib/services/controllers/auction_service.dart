import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/auction_data.dart';
import 'package:mators_car/services/api_exception.dart';

// خدمة المزادات والعربون — تطابق قسم "06 - المزادات والعربون" في Postman
class AuctionService {
  final AuctionData _data = AuctionData();

  // قائمة المزادات (نشطة/كل المزادات حسب الفلاتر الافتراضية للسيرفر)
  // GET /auctions يعرض حالة "active" فقط افتراضياً حسب توثيق الـ API،
  // لذلك نمرر status صراحة لجلب حالات أخرى مثل "pending" أيضاً.
  Future<List<Map<String, dynamic>>> getAuctions({String? status}) async {
    final response = await _data.getAuctions(status: status);
    _handleResponseErrors(response, 'جلب المزادات');
    return _normalizeList(response.data);
  }

  // ⬅️ جديد: مزادات المستخدم الحالي بكل حالاتها مباشرة من endpoint مخصص
  // (GET /my-auctions)، بدل الحل الالتفافي القديم (جلب كل الحالات عبر
  // GET /auctions ثم مطابقتها يدوياً مع GET /my-cars).
  Future<List<Map<String, dynamic>>> getMyAuctions({
    String? status,
    String? timeStatus,
  }) async {
    final response = await _data.getMyAuctions(
      status: status,
      timeStatus: timeStatus,
    );
    _handleResponseErrors(response, 'جلب مزاداتي');
    return _normalizeList(response.data);
  }

  // عرض مزاد بالتفصيل — بعد إصلاح GET /auctions/{id} بالباك-إند (صار
  // يسمح لصاحب المزاد/الفائز/أي مزايد شارك فيه برؤية التفاصيل حتى بعد
  // الإغلاق)، لم نعد بحاجة للبحث الاحتياطي عبر القوائم العامة.
  Future<Map<String, dynamic>> getAuctionDetails(int auctionId) async {
    final response = await _data.getAuctionDetails(auctionId);
    _handleResponseErrors(response, 'جلب تفاصيل المزاد');
    return _normalizeResponse(response.data);
  }

  // إنشاء مزاد جديد على سيارة أملكها
  Future<Map<String, dynamic>> createAuction({
    required int carId,
    required double startingPrice,
    required int durationHours,
  }) async {
    final response = await _data.createAuction(
      carId: carId,
      startingPrice: startingPrice,
      durationHours: durationHours,
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
    final response = await _data.updateAuction(
      auctionId: auctionId,
      startingPrice: startingPrice,
      durationHours: durationHours,
    );
    _handleResponseErrors(response, 'تعديل المزاد');
    return _normalizeResponse(response.data);
  }

  // تقديم مزايدة + حجز العربون تلقائياً من المحفظة
  Future<Map<String, dynamic>> placeBid({
    required int auctionId,
    required double amount,
  }) async {
    final response = await _data.placeBid(auctionId: auctionId, amount: amount);
    _handleResponseErrors(response, 'تقديم المزايدة');
    return _normalizeResponse(response.data);
  }

  // إغلاق المزادات المنتهية يدوياً (غالباً للاستخدام الإداري/المجدول)
  Future<void> closeExpiredAuctions() async {
    final response = await _data.closeExpiredAuctions();
    _handleResponseErrors(response, 'إغلاق المزادات المنتهية');
  }

  // البائع يقبل السعر النهائي بعد انتهاء المزاد
  Future<Map<String, dynamic>> acceptFinalPrice(int auctionId) async {
    final response = await _data.acceptFinalPrice(auctionId);
    _handleResponseErrors(response, 'قبول السعر النهائي');
    return _normalizeResponse(response.data);
  }

  // البائع يرفض السعر النهائي بعد انتهاء المزاد
  Future<Map<String, dynamic>> rejectFinalPrice(int auctionId) async {
    final response = await _data.rejectFinalPrice(auctionId);
    _handleResponseErrors(response, 'رفض السعر النهائي');
    return _normalizeResponse(response.data);
  }

  // تأكيد إتمام عملية البيع بعد اللقاء خارج التطبيق
  Future<Map<String, dynamic>> completeSale(int auctionId) async {
    final response = await _data.completeSale(auctionId);
    _handleResponseErrors(response, 'تأكيد إتمام البيع');
    return _normalizeResponse(response.data);
  }

  // الفائز يتراجع عن الصفقة (قد يفقد العربون حسب سياسة السيرفر)
  Future<Map<String, dynamic>> winnerWithdraw(int auctionId) async {
    final response = await _data.winnerWithdraw(auctionId);
    _handleResponseErrors(response, 'التراجع عن المزاد');
    return _normalizeResponse(response.data);
  }

  Future<void> deleteAuction(int auctionId) async {
    final response = await _data.deleteAuction(auctionId);
    _handleResponseErrors(response, 'حذف المزاد');
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
