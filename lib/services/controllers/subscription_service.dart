import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/subscription_data.dart';
import 'package:mators_car/services/api_exception.dart';

// خدمة الاشتراكات — تطابق قسم "08 - الاشتراكات" في Postman
class SubscriptionService {
  final SubscriptionData _data = SubscriptionData();

  // جلب حالة الاشتراك الحالية للمستخدم
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final response = await _data.getSubscriptionStatus();
    _handleResponseErrors(response, 'جلب حالة الاشتراك');
    return _normalizeResponse(response.data);
  }

  // الاشتراك الشهري (يُخصم المبلغ من رصيد المحفظة على الأغلب من طرف السيرفر)
  Future<Map<String, dynamic>> subscribe() async {
    final response = await _data.subscribe();
    _handleResponseErrors(response, 'الاشتراك الشهري');
    return _normalizeResponse(response.data);
  }

  // إلغاء الاشتراك الحالي
  Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _data.cancelSubscription();
    _handleResponseErrors(response, 'إلغاء الاشتراك');
    return _normalizeResponse(response.data);
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  // يفحص كامل شجرة الـ JSON (بغض النظر عن عمق التداخل) بحثاً عن أي إشارة
  // لاشتراك نشط. لا نفترض شكلاً معيناً لرد GET /subscription لأنه غير موثّق
  // بـ Postman (response فارغ)، فنبحث بمرونة عن أي مفتاح يحتوي كلمة status/
  // active/subscribed بأي مكان بالشجرة، بدل الاعتماد على مسار ثابت.
  static bool isActive(Map<String, dynamic> response) {
    bool found = false;
    void walk(dynamic node) {
      if (found) return;
      if (node is Map) {
        node.forEach((key, value) {
          if (found) return;
          final k = key.toString().toLowerCase();
          if (value is Map || value is List) {
            walk(value);
            return;
          }
          if (value == null) return;
          final v = value.toString().toLowerCase().trim();

          if (k.contains('status') &&
              (v == 'active' || v == 'نشط' || v == 'current')) {
            found = true;
            return;
          }
          if ((k.contains('is_active') ||
                  k.contains('active') ||
                  k.contains('subscribed')) &&
              !k.contains('inactive') &&
              (v == 'true' || v == '1')) {
            found = true;
            return;
          }
          if (k.contains('end') ||
              k.contains('expire') ||
              k.contains('expiry') ||
              k.contains('valid_until') ||
              k.contains('period_end')) {
            final date = DateTime.tryParse(value.toString());
            if (date != null && date.isAfter(DateTime.now())) {
              found = true;
            }
          }
        });
      } else if (node is List) {
        for (final item in node) {
          if (found) return;
          walk(item);
        }
      }
    }

    walk(response);
    return found;
  }

  // يبحث بنفس المرونة عن أول تاريخ انتهاء بكامل الشجرة لعرضه بالواجهة.
  static String? endDate(Map<String, dynamic> response) {
    String? result;
    void walk(dynamic node) {
      if (result != null) return;
      if (node is Map) {
        node.forEach((key, value) {
          if (result != null) return;
          final k = key.toString().toLowerCase();
          if (value is Map || value is List) {
            walk(value);
            return;
          }
          if (value == null) return;
          if (k.contains('end') ||
              k.contains('expire') ||
              k.contains('expiry') ||
              k.contains('valid_until') ||
              k.contains('period_end')) {
            if (DateTime.tryParse(value.toString()) != null) {
              result = value.toString();
            }
          }
        });
      } else if (node is List) {
        for (final item in node) {
          if (result != null) return;
          walk(item);
        }
      }
    }

    walk(response);
    return result;
  }

  // السعر موثّق بـ Postman كقيمة ثابتة حسب نوع الحساب (فردي/شركة)، وليس
  // حقلاً يُرجعه GET /subscription، لذلك نعرضه بناءً على نوع الحساب مباشرة.
  static int priceFor(String? accountType) =>
      accountType == 'company' ? 10000 : 20000;

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
