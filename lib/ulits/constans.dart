import 'package:flutter/foundation.dart';

class AppConstants {
  // ⚠️ ضع هنا المفتاح العلني (Publishable Key) لحساب Stripe الخاص بك
  // (يبدأ بـ pk_test_... في وضع الاختبار أو pk_live_... بالإنتاج).
  // يمكن الحصول عليه من: https://dashboard.stripe.com/apikeys
  // لا تضع أبداً المفتاح السري (sk_...) هنا — هذا الملف موجود على جهاز المستخدم.
  static const String stripePublishableKey = 'pk_test_ضع_مفتاحك_هنا';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
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
