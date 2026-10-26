import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

// --- English Themes ---
ThemeData appThemeEnglish = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryNavy),
  fontFamily: "PlayfairDisplay",
  scaffoldBackgroundColor: AppColors.bgLight,
  cardTheme: const CardThemeData(color: AppColors.surfaceLight),
  appBarTheme: const AppBarThemeData(
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    backgroundColor: AppColors.bgLight,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryLight,
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  dialogTheme: const DialogThemeData(
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
    ),
    backgroundColor: AppColors.bgLight,
  ),
  inputDecorationTheme: const InputDecorationThemeData(
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.borderGrey),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryNavy,
      foregroundColor: Colors.white,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryNavy,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.textPrimaryLight,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.primaryNavy,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(color: AppColors.textSecondaryLight, fontSize: 16),
  ),
);

ThemeData appThemeEnglishDark = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.buttonBlue,
    brightness: Brightness.dark,
  ),
  fontFamily: "PlayfairDisplay",
  scaffoldBackgroundColor: AppColors.bgDark,
  cardTheme: const CardThemeData(color: AppColors.surfaceDark),
  appBarTheme: const AppBarThemeData(
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    backgroundColor: AppColors.bgDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryDark,
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  dialogTheme: const DialogThemeData(
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    ),
    backgroundColor: AppColors.bgDark,
  ),
  inputDecorationTheme: const InputDecorationThemeData(
    filled: true,
    fillColor: AppColors.surfaceDark2,
    border: OutlineInputBorder(),
  ),
  dividerTheme: const DividerThemeData(color: Colors.white24),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.buttonBlue),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.buttonBlue,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.textPrimaryDark,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textSecondaryDark,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(color: AppColors.textPrimaryDark, fontSize: 16),
  ),
);

// --- Arabic Themes ---
ThemeData appThemeArabic = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryNavy),
  fontFamily: "Cairo",
  scaffoldBackgroundColor: AppColors.bgLight,
  cardTheme: const CardThemeData(color: AppColors.surfaceLight),
  appBarTheme: const AppBarThemeData(
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    backgroundColor: AppColors.bgLight,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryLight,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.textPrimaryLight,
      fontSize: 26,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.primaryNavy,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(color: AppColors.textSecondaryLight, fontSize: 15),
  ),
  inputDecorationTheme: const InputDecorationThemeData(
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.borderGrey),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryNavy,
      foregroundColor: Colors.white,
    ),
  ),
);

ThemeData appThemeArabicDark = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.buttonBlue,
    brightness: Brightness.dark,
  ),
  fontFamily: "Cairo",
  scaffoldBackgroundColor: AppColors.bgDark,
  cardTheme: const CardThemeData(color: AppColors.surfaceDark),
  appBarTheme: const AppBarThemeData(
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    backgroundColor: AppColors.bgDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryDark,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  dialogTheme: const DialogThemeData(
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    ),
    backgroundColor: AppColors.bgDark,
  ),
  inputDecorationTheme: const InputDecorationThemeData(
    filled: true,
    fillColor: AppColors.surfaceDark2,
    border: OutlineInputBorder(),
  ),
  dividerTheme: const DividerThemeData(color: Colors.white24),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.buttonBlue),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.buttonBlue,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.textPrimaryDark,
      fontSize: 26,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: AppColors.textSecondaryDark,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle(color: AppColors.textPrimaryDark, fontSize: 15),
  ),
);
