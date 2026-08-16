// استثناء موحّد لأخطاء الـ API.
// يحمل statusCode الحقيقي القادم من السيرفر (403, 422, 500 ...) مع رسالة
// عربية جاهزة للعرض، بدل تسريب نص DioException الخام للمستخدم.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  // حالة خاصة شائعة: رفض الطلب لأن الاشتراك غير نشط
  bool get isSubscriptionRequired {
    if (statusCode != 403) return false;
    final text = message.toLowerCase();
    return text.contains('اشتراك') ||
        text.contains('subscription') ||
        text.contains('subscribe');
  }

  bool get isForbidden => statusCode == 403;

  // حالة شائعة أخرى: رفض الطلب لعدم كفاية رصيد المحفظة (مزايدة، اشتراك، شحن...)
  bool get isInsufficientBalance {
    final text = message.toLowerCase();
    return text.contains('رصيد') ||
        text.contains('insufficient') ||
        text.contains('balance');
  }

  @override
  String toString() => message;
}
