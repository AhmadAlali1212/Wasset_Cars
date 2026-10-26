import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي بسيط (Offline cache) لآخر استجابة ناجحة من الشاشات الرئيسية
/// بالتطبيق — لا يوجد أي تخزين محلي حالياً، فأي انقطاع اتصال يعني شاشة
/// فاضية بدل عرض آخر بيانات محفوظة. هذا حل عملي وخفيف باستخدام
/// shared_preferences (متوفرة أصلاً بالمشروع)، بدون قاعدة بيانات محلية
/// كاملة (sqflite/hive) كخطوة أولى تغطي أهم شاشة (الرئيسية).
class LocalCache {
  static const String _prefixKey = 'local_cache_';
  static const String _timestampSuffix = '_ts';

  /// حفظ بيانات (قائمة أو خريطة قابلة للتحويل JSON) تحت مفتاح معيّن.
  static Future<void> save(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefixKey$key', jsonEncode(data));
      await prefs.setInt(
        '$_prefixKey$key$_timestampSuffix',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // فشل الحفظ المحلي ليس خطأ يستحق مقاطعة المستخدم
    }
  }

  /// قراءة بيانات محفوظة مسبقاً (أو null إن لم توجد/فشل التحويل).
  static Future<dynamic> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefixKey$key');
      if (raw == null) return null;
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// وقت آخر حفظ لهذا المفتاح (لعرض "آخر تحديث منذ..." للمستخدم).
  static Future<DateTime?> lastSavedAt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt('$_prefixKey$key$_timestampSuffix');
      if (ms == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }
}
