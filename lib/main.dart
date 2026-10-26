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
import 'package:mators_car/services/controllers/auth_serivces.dart';
import 'package:mators_car/services/controllers/push_notification_service.dart';
import 'package:mators_car/services/my_service.dart';
import 'package:mators_car/services/navigation_service.dart';
import 'package:mators_car/ulits/constant.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/ulits/localization/changed_local.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  /*
$downloadUrl = "https://github.com/getsentry/sentry-wizard/releases/download/v4.0.1/sentry-wizard-win-x64.exe"
Invoke-WebRequest $downloadUrl -OutFile sentry-wizard.exe
./sentry-wizard.exe -i flutter --saas --org ahmad-5f --project wassetak_cars */
  // لا ننتظر (await) هذه، حتى لا تؤخر إقلاع الواجهة — تعمل بالخلفية
  // وتسجّل رمز الجهاز تلقائياً لو كان المستخدم مسجلاً دخوله مسبقاً.
  unawaited(PushNotificationService.instance.init());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ChangedLocalProvider>(
          create: (_) => ChangedLocalProvider(myService: myService),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
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
