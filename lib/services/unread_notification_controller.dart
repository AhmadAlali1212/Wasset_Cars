import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mators_car/services/controllers/notification_service.dart';

/// مصدر واحد مشترك لعدد الإشعارات غير المقروءة، بدل أن يجلب كل Header
/// بكل شاشة هذا العدد بشكل منفصل (نفس الطلب يتكرر مرة لكل شاشة فيها
/// Header). كل نسخ [AppHomeStyleHeader] تستمع لنفس الـ [ChangeNotifier]
/// هنا، فيصير هناك مؤقت واحد فقط وطلب واحد فقط، بدل مؤقت مستقل بكل شاشة.
///
/// هذا حل خفيف بدون إضافة مكتبة إدارة حالة جديدة (Provider/Riverpod)،
/// كخطوة أولى عملية تجاه "مصدر بيانات مشترك" بدل حل جذري يحتاج تعديل
/// شجرة الـ widgets بالكامل.
class UnreadNotificationController extends ChangeNotifier {
  UnreadNotificationController._internal();
  static final UnreadNotificationController instance =
      UnreadNotificationController._internal();

  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Timer? _pollTimer;
  int _listenerCount = 0;

  /// تُستدعى من initState لأي Header جديد يظهر على الشاشة. تبدأ الاستطلاع
  /// الدوري مرة واحدة فقط (عند أول مستمع)، وتُعيد استخدامه لبقية الشاشات.
  void attach() {
    _listenerCount++;
    if (_pollTimer == null) {
      refresh();
      _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    }
  }

  /// تُستدعى من dispose لأي Header يُزال من الشجرة. يتوقف الاستطلاع فقط
  /// عندما لا تبقى أي شاشة تستخدم Header (لا داعي للاستمرار بالخلفية).
  void detach() {
    _listenerCount = (_listenerCount - 1).clamp(0, 1 << 30);
    if (_listenerCount == 0) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _notificationService.getNotifications(page: 1);
      _unreadCount = page.unreadCount;
      notifyListeners();
    } catch (_) {
      // فشل صامت — عداد خلفي، لا يستحق إزعاج المستخدم
    }
  }
}
