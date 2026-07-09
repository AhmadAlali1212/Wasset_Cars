import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mators_car/screens/adsCar/rental/add_rental_Ad_screen.dart';
import 'package:mators_car/screens/auth/login_screen.dart';
import 'package:mators_car/screens/intro_screen.dart';
import 'package:mators_car/screens/main_screen.dart';
import 'package:mators_car/services/auth_serivces.dart';
import 'package:mators_car/services/my_service.dart';
import 'package:mators_car/services/navigation_service.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/ulits/localization/changed_local.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final isLoggedIn = await authService.checkAuth();

  final myService = await MyService().init();

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
      title: 'Maters Car',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: isLoggedIn ? '/home' : '/welcome',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
        '/home': (context) => const MainScreen(),
        '/welcome': (context) => const IntroScreen(),

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
