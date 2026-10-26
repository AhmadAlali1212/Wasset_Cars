import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../api/dio_client.dart';
import '../../data/models/promotion_model.dart';
import '../api_exception.dart';

// خدمة العروض الترويجية — تطابق قسم "09 - العروض الترويجية" في Postman
// ملاحظة مهمة: العرض الترويجي حسب الـ API ليس مرتبطاً بسيارة/إعلان محدد
// (لا يوجد car_id أو ad_id في بنية العرض) بل هو حملة تسويقية عامة تابعة
// للشركة (عنوان + نسبة/قيمة خصم + تاريخ بداية ونهاية + الكمية المتاحة).
// ملاحظة: إنشاء عرض ترويجي يتطلب اشتراكاً نشطاً (راجع وصف الطلب في Postman).
class PromotionService {
  final Dio _dio = DioClient.instance.dio;

  // قائمة العروض الترويجية النشطة ضمن تواريخها (عامة لكل المستخدمين)
  Future<List<Map<String, dynamic>>> getPromotions() async {
    final response = await _dio.get(
      '/promotions',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب العروض الترويجية');
    return _normalizeList(response.data);
  }

  // بما أن العرض الترويجي غير مرتبط بسيارة معينة بل بصاحب الحساب (شركة/فرد)،
  // نستخدم هذه الدالة لمعرفة كل المستخدمين اللي عندهم عرض نشط حالياً، ليتم
  // عرض شارة "عليه عرض" على كل سيارات نفس المستخدم بقوائم السيارات.
  Future<Set<int>> getPromotedOwnerIds() async {
    return extractOwnerIds(await getPromotions());
  }

  // استخراج معرفات الملاك من قائمة عروض مجلوبة مسبقاً (بدون طلب شبكة إضافي)
  static Set<int> extractOwnerIds(List<Map<String, dynamic>> promotions) {
    final ids = <int>{};
    for (final json in promotions) {
      final direct = json['user_id'] ?? json['company_id'] ?? json['owner_id'];
      int? ownerId = direct != null ? int.tryParse('$direct') : null;
      if (ownerId == null) {
        final userObj = json['user'] ?? json['company'];
        if (userObj is Map) ownerId = int.tryParse('${userObj['id']}');
      }
      if (ownerId != null) ids.add(ownerId);
    }
    return ids;
  }

  // يجلب العروض النشطة فعلياً (معتمدة وضمن الفترة الزمنية) مجمّعة حسب
  // صاحب العرض (شركة/معرض)، لعرض قسم "العروض الترويجية" مقسّماً حسب كل
  // شركة مع عرضها الفعلي (النوع/القيمة/تاريخ الانتهاء). إن كان لنفس
  // الشركة أكثر من عرض نشط، تُعتمد أقربها انتهاءً.
  Future<Map<int, Promotion>> getActivePromotionsByOwner() async {
    final rawList = await getPromotions();
    final promotions =
        rawList
            .map((json) => Promotion.fromJson(json))
            .where((p) => p.isActiveNow && p.ownerId != null)
            .toList();

    final byOwner = <int, Promotion>{};
    for (final promo in promotions) {
      final existing = byOwner[promo.ownerId!];
      if (existing == null) {
        byOwner[promo.ownerId!] = promo;
        continue;
      }
      final existingEnd = existing.endDate;
      final currentEnd = promo.endDate;
      if (existingEnd != null &&
          currentEnd != null &&
          currentEnd.isBefore(existingEnd)) {
        byOwner[promo.ownerId!] = promo;
      }
    }
    return byOwner;
  }

  Future<Map<String, dynamic>> getPromotionDetails(int promotionId) async {
    final response = await _dio.get(
      '/promotions/$promotionId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب تفاصيل العرض الترويجي');
    return _normalizeResponse(response.data);
  }

  // إنشاء عرض ترويجي جديد (يتطلب اشتراكاً نشطاً من طرف الشركة)
  Future<Map<String, dynamic>> createPromotion({
    required String title,
    required String description,
    required String type,
    required double value,
    required DateTime startDate,
    required DateTime endDate,
    required int quantity,
  }) async {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.post(
      '/promotions',
      data: {
        'title': title,
        'description': description,
        'type': type,
        'value': value,
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
        'quantity': quantity,
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'إنشاء العرض الترويجي');
    return _normalizeResponse(response.data);
  }

  Future<Map<String, dynamic>> updatePromotion({
    required int promotionId,
    required String title,
    required String description,
    required String type,
    required double value,
    required DateTime startDate,
    required DateTime endDate,
    required int quantity,
  }) async {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.put(
      '/promotions/$promotionId',
      data: {
        'title': title,
        'description': description,
        'type': type,
        'value': value,
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
        'quantity': quantity,
      },
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تعديل العرض الترويجي');
    return _normalizeResponse(response.data);
  }

  Future<void> deletePromotion(int promotionId) async {
    final response = await _dio.delete(
      '/promotions/$promotionId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'حذف العرض الترويجي');
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
      for (final key in ['data', 'promotions', 'items', 'results']) {
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
    if (data is Map && data['promotion'] is Map) {
      return Map<String, dynamic>.from(data['promotion'] as Map);
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
