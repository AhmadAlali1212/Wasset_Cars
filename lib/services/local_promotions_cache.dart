import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// GET /promotions يُرجع العروض النشطة فقط (موثّق بـ Postman: "يعرض العروض
// النشطة ضمن تواريخها")، ولا يوجد endpoint عام لعرض "عروضي بكل الحالات".
// لذلك نخزّن محلياً كل عرض أنشأه المستخدم للتو وما زال قيد المراجعة،
// وندمجه مع قائمة السيرفر عند العرض حتى لا يختفي فوراً بعد إنشائه.
// بمجرد ما يصير معتمداً (يظهر ضمن رد السيرفر نفسه)، نحذفه من الكاش تلقائياً.
class LocalPromotionsCache {
  static const _key = 'pending_promotions_cache_v1';

  static Future<void> add(Map<String, dynamic> promotion) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _readAll(prefs);
    final id = promotion['id'];
    all.removeWhere((p) => p['id'] == id);
    all.add(promotion);
    await prefs.setString(_key, jsonEncode(all));
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _readAll(prefs);
  }

  // يحذف من الكاش أي عرض صار موجوداً فعلياً برد السيرفر (اعتماده صار حقيقياً)
  static Future<void> reconcile(List<Map<String, dynamic>> serverIds) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _readAll(prefs);
    final serverIdSet = serverIds.map((p) => p['id']).toSet();
    all.removeWhere((p) => serverIdSet.contains(p['id']));
    await prefs.setString(_key, jsonEncode(all));
  }

  static Future<List<Map<String, dynamic>>> _readAll(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {
      // كاش تالف؛ نتجاهله
    }
    return [];
  }
}
