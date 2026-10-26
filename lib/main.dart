import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mators_car/screens/adsCar/rental/add_rental_Ad_screen.dart';
import 'package:mators_car/screens/auth/login_screen.dart';
import 'package:mators_car/screens/intro_screen.dart';
import 'package:mators_car/screens/main_screen.dart';
import 'package:mators_car/screens/notifications/notifications_screen.dart';
import 'package:mators_car/services/controllers/auth_service.dart';
import 'package:mators_car/services/my_service.dart';
import 'package:mators_car/services/navigation_service.dart';
import 'package:mators_car/services/controllers/push_notification_service.dart';
import 'package:mators_car/ulits/constans.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/ulits/localization/changed_local.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase — لازمة قبل أي استخدام لـ FirebaseMessaging (إشعارات
  // push). ملف android/app/google-services.json يجب أن يكون موجوداً
  // (راجع خطوات ربط FCM).
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // تهيئة Stripe SDK مرة واحدة عند إقلاع التطبيق — لازمة لأي عملية دفع
  // (شحن المحفظة عبر /wallet/stripe/create-intent) قبل استدعاء أي واجهة دفع.
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  // ⬅️ جديد: مطلوب لتفعيل Apple Pay ضمن ورقة الدفع (بدونه Apple Pay
  // يبقى غير مفعّل حتى لو مررنا applePay: true لاحقاً).
  Stripe.merchantIdentifier = AppConstants.stripeMerchantIdentifier;
  await Stripe.instance.applySettings();

  final authService = AuthService();
  final isLoggedIn = await authService.checkAuth();

  final myService = await MyService().init();

  // لا ننتظر (await) هذه، حتى لا تؤخر إقلاع الواجهة — تعمل بالخلفية
  // وتسجّل رمز الجهاز تلقائياً لو كان المستخدم مسجلاً دخوله مسبقاً.
  unawaited(PushNotificationService.instance.init());

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://54e9cd2dc8fd8bdfaf320f7283774458@o4512079094677504.ingest.us.sentry.io/4512079129280512';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: 
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ChangedLocalProvider>(
          create: (_) => ChangedLocalProvider(myService: myService),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  )),
  );
  // TODO: Remove this line after sending the first sample event to sentry.
  await Sentry.captureException(Exception('This is a sample exception.'));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<ChangedLocalProvider>(context);

    return MaterialApp(
      title: 'Wassetak Cars',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: isLoggedIn ? '/home' : '/welcome',
      // ⬅️ جديد: ChangedLocalProvider كان يحتفظ فعلياً بكل منطق الوضع
      // الليلي وثيمَي اللغتين (lightTheme/darkTheme/themeMode) ويحفظه
      // بـ SharedPreferences، لكن MaterialApp لم يكن يستخدمها إطلاقاً —
      // الوضع الليلي كان بلا أي تأثير رغم وجود كل الكود اللازم له.
      theme: localeProvider.lightTheme,
      darkTheme: localeProvider.darkTheme,
      themeMode: localeProvider.themeMode,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
        '/home': (context) => const MainScreen(),
        '/welcome': (context) => const IntroScreen(),
        '/notifications': (context) => const NotificationsScreen(),

        // '/subscription': (context) => const SubscriptionPlansScreen(),
        // '/add-rental': (context) => const AddRentalAdScreen(),
        // '/auctions': (context) => const AuctionsScreen(),
      },
      locale: localeProvider.language ?? const Locale('ar'),
      supportedLocales: const [Locale('ar', ''), Locale('en', '')],

      // ربط ملف الـ AppLocalizations الخاص بنا مع نظام فلاتر الأساسي
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AddRentalAdScreen(),
        );
      },
    );
  }
}
