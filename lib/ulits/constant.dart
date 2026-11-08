import 'package:flutter/foundation.dart';

class AppConstants {
  // ⚠️ ضع هنا المفتاح العلني (Publishable Key) لحساب Stripe الخاص بك
  // (يبدأ بـ pk_test_... في وضع الاختبار أو pk_live_... بالإنتاج).
  // يمكن الحصول عليه من: https://dashboard.stripe.com/apikeys
  // لا تضع أبداً المفتاح السري (sk_...) هنا — هذا الملف موجود على جهاز المستخدم.
  static const String stripePublishableKey = 'pk_test_ضع_مفتاحك_هنا';

  // ⬅️ جديد: مطلوبان لتفعيل Apple Pay / Google Pay عبر ورقة دفع Stripe.
  // merchantIdentifier: مُعرّف التاجر من Apple (Merchant ID) الذي تنشئه
  // بحساب Apple Developer الخاص بك من:
  // https://developer.apple.com/account/resources/identifiers/list/merchant
  // بصيغة "merchant.com.yourcompany.appname"، ثم فعّل Apple Pay كـ
  // Capability بمشروع Xcode (Signing & Capabilities) واربط نفس الـ
  // Merchant ID هناك — هذا الجزء خارج مجلد lib ولا يمكن ضبطه من هنا.
  static const String stripeMerchantIdentifier =
      'merchant.com.syriamotor.app'; // ⚠️ استبدله بمُعرّف التاجر الحقيقي الخاص بك
  // كود الدولة الذي يعمل به حسابك على Stripe (SY غير مدعوم من Stripe
  // مباشرة؛ عدّله ليطابق بلد حساب Stripe الفعلي الذي تستخدمه، مثل AE).
  static const String stripeMerchantCountryCode = 'AE';
  static const String stripeCurrencyCode = 'usd';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        //  return "http://192.168.92.1/api";
        return "http://10.0.2.2:8000/api";
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8000/api';
    }
  }

  // خادم الملفات/الصور هو نفس مضيف الـ API لكن بدون بادئة "/api"
  // (السيرفر Laravel يخدم الصور المرفوعة من جذر الموقع عبر storage/... )
  static String get mediaBaseUrl {
    final url = baseUrl;
    return url.endsWith('/api') ? url.substring(0, url.length - 4) : url;
  }

  // يحوّل مسار صورة قادم من الـ API (نسبي مثل "storage/cars/x.jpg" أو
  // "/storage/cars/x.jpg") إلى رابط كامل صالح لـ Image.network.
  // إن كان الرابط مكتملاً أصلاً (يبدأ بـ http/https) يُعاد كما هو.
  static String? resolveImageUrl(dynamic path) {
    if (path == null) return null;
    final raw = path.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final normalized = raw.startsWith('/') ? raw : '/$raw';
    return '$mediaBaseUrl$normalized';
  }
}
