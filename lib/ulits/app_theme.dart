import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

// --- English Themes ---
ThemeData appThemeEnglish = ThemeData(
  brightness: Brightness.light,
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
);

ThemeData appThemeArabicDark = ThemeData(
  brightness: Brightness.dark,
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
