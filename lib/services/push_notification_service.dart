import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/screens/notifications/notifications_screen.dart';
import 'package:mators_car/services/navigation_service.dart';
import 'package:mators_car/ulits/constans.dart';

// القناة نفسها المعرّفة في AndroidManifest.xml
// (com.google.firebase.messaging.default_notification_channel_id)
// يجب أن يتطابق المعرّف هنا معها تماماً.
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'إشعارات مهمة',
  description: 'إشعارات سوريا موتورز (مزادات، طلبات، عروض...)',
  importance: Importance.high,
);

// معالج الرسائل بالخلفية: يعمل Dart في isolate منفصل عن الواجهة، لذلك
// يجب أن تكون هذه دالة top-level (خارج أي كلاس) ومعلَّمة بـ
// @pragma('vm:entry-point')، وتُهيّئ Firebase من جديد بنفسها.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // لا حاجة لعرض إشعار يدوياً هنا: أي رسالة تحمل حقل "notification"
  // يعرضها نظام Android/iOS تلقائياً حتى لو كان التطبيق مغلقاً بالكامل.
  // هذا المعالج مخصص فقط لأي معالجة بيانات إضافية إن احتجتها لاحقاً.
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  late final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  bool _initialized = false;
  String? _lastRegisteredToken;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _setupLocalNotifications();

    // على iOS/الويب يطلب صلاحية صريحة؛ على أندرويد <13 تُمنح تلقائياً،
    // و13+ تُطلب عبر إذن POST_NOTIFICATIONS المعرّف بالـ manifest.
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // رسالة تصل والتطبيق بالمقدمة (foreground) — النظام لا يعرضها تلقائياً
    // بهذه الحالة، لذلك نعرضها يدوياً كإشعار محلي فوري.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // المستخدم ضغط على إشعار والتطبيق كان بالخلفية (وليس مغلقاً بالكامل)
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());

    // التطبيق كان مغلقاً بالكامل وفُتح عبر الضغط على إشعار
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _openNotifications();
    }

    // Firebase قد يجدّد رمز الجهاز تلقائياً بين الحين والآخر
    _messaging.onTokenRefresh.listen((token) => _registerToken(token));

    // تسجيل الرمز الحالي فوراً لو كان المستخدم مسجلاً دخوله مسبقاً (مثلاً
    // عند إعادة فتح التطبيق)، لا فقط بعد تسجيل دخول جديد
    final isLoggedIn = await AuthStorage.getToken() != null;
    if (isLoggedIn) {
      await syncTokenWithBackend();
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (_) => _openNotifications(),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _openNotifications() {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  // يُستدعى بعد نجاح تسجيل الدخول/التسجيل مباشرة (من AuthService)
  Future<void> syncTokenWithBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _registerToken(token);
    } catch (_) {
      // فشل الحصول على الرمز (مثلاً على المحاكي بدون خدمات Google) لا
      // يجب أن يمنع تسجيل الدخول من إتمامه
    }
  }

  Future<void> _registerToken(String token) async {
    if (_lastRegisteredToken == token) return;
    try {
      final authToken = await AuthStorage.getToken();
      if (authToken == null) return;
      await _dio.post(
        '/device-tokens',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        ),
      );
      _lastRegisteredToken = token;
    } catch (_) {
      // فشل صامت — لا داعي لإزعاج المستخدم، ستتم إعادة المحاولة في
      // المرة القادمة التي يُستدعى فيها syncTokenWithBackend
    }
  }

  // يُستدعى قبل تسجيل الخروج مباشرة (من AuthService.logout) حتى لا يستمر
  // الجهاز باستقبال إشعارات حساب لم يعد مسجلاً دخوله عليه
  Future<void> unregisterFromBackend() async {
    try {
      final authToken = await AuthStorage.getToken();
      final token = _lastRegisteredToken ?? await _messaging.getToken();
      if (authToken == null || token == null) return;
      await _dio.delete(
        '/device-tokens',
        data: {'token': token},
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        ),
      );
      _lastRegisteredToken = null;
    } catch (_) {
      // فشل صامت — الرمز سينتهي فعلياً على أي حال بعد إبطال جلسة السيرفر
    }
  }
}
