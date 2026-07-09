import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mators_car/services/my_service.dart';
import 'package:mators_car/ulits/app_theme.dart';

class ChangedLocalProvider with ChangeNotifier {
  Locale? _language;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false;
  ThemeData _lightTheme = appThemeEnglish;
  ThemeData _darkTheme = appThemeEnglishDark;

  final MyService myService;

  ChangedLocalProvider({required this.myService}) {
    _initSettings();
  }

  Locale? get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  void _initSettings() {
    String? sharedPreflang = myService.sharedPreference.getString("lang");
    String? savedTheme = myService.sharedPreference.getString("theme");

    _isDarkMode = savedTheme == "dark";
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;

    if (sharedPreflang == null) {
      sharedPreflang = "ar";
      myService.sharedPreference.setString("lang", sharedPreflang);
    }

    if (sharedPreflang == "ar") {
      _language = const Locale("ar");
      _lightTheme = appThemeArabic;
      _darkTheme = appThemeArabicDark;
    } else {
      _language = const Locale("en");
      _lightTheme = appThemeEnglish;
      _darkTheme = appThemeEnglishDark;
    }
    requestPerLocation();
  }

  void changeLang(String langCode) {
    _language = Locale(langCode);
    myService.sharedPreference.setString("lang", langCode);

    if (langCode == "ar") {
      _lightTheme = appThemeArabic;
      _darkTheme = appThemeArabicDark;
    } else {
      _lightTheme = appThemeEnglish;
      _darkTheme = appThemeEnglishDark;
    }

    notifyListeners();
  }

  void changeThemeMode(bool darkMode) {
    _isDarkMode = darkMode;
    _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    myService.sharedPreference.setString("theme", darkMode ? "dark" : "light");
    notifyListeners();
  }

  Future<void> requestPerLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    await Geolocator.getCurrentPosition();
  }
}
