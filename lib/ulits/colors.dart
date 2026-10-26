import 'package:flutter/material.dart';

export '../widgets/common/app_snackbar.dart';

class AppColors {
  // Primary Colors
  static const primary = Color(0xFF4361EE);
  static const primaryDark = Color(0xFF3A0CA3);
  static const primaryLight = Color(0xFF4895EF);
  static const newPrimary = Color(0xFF051329);
  // Secondary Colors
  static const secondary = Color(0xFFF72585);
  static const secondaryLight = Color(0xFFB5179E);

  // Background & Surface
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFFE9ECEF);

  // Text Colors
  static const textPrimary = Color(0xFF212529);
  static const textSecondary = Color(0xFF495057);
  static const textDisabled = Color(0xFFADB5BD);

  // Status Colors
  static const success = Color(0xFF4BB543);
  static const warning = Color(0xFFFCA311);
  static const error = Color(0xFFE71D36);
  static const info = Color(0xFF2EC4B6);

  static const Color bgLight = Colors.white;
  static const Color surfaceLight = Color(
    0xFFF8FAFC,
  ); // رمادي ناعم جداً للخلفيات الفرعية
  static const Color textPrimaryLight = Color(0xFF1F2937); // أسود داكن للنصوص
  static const Color textSecondaryLight = Color(
    0xFF6B7280,
  ); // رمادي للنصوص الفرعية

  // الألوان الرئيسية المظلمة (Dark Mode)
  static const Color bgDark = Color(0xFF0F172A); // أزرق داكن غامق جداً للخلفية
  static const Color surfaceDark2 = Color(
    0xFF1E293B,
  ); // أزرق رمادي للبطاقات والحقول
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ألوان الهوية البصرية (Carvana Style)
  static const Color primaryNavy = Color(
    0xFF002F6C,
  ); // الأزرق الداكن العميق (الخلفية الافتتاحية والأزرار)
  static const Color buttonBlue = Color(
    0xFF1E73BE,
  ); // الأزرق الفاتح الساطع (مثل زر Get Started)
  static const Color borderGrey = Color(
    0xFFE5E7EB,
  ); // رمادي خفيف للحدود والحقول

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [newPrimary, newPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

double parsePrice(String price) {
  try {
    return double.parse(price.replaceAll(',', ''));
  } catch (e) {
    return 0.0;
  }
}
