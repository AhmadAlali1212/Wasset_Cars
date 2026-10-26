import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

/// امتداد بسيط يعطي كل شاشة وصولاً سريعاً لألوان "متكيّفة" حسب الوضع
/// الحالي (فاتح/داكن) بدل تكرار `Theme.of(context).brightness == Brightness.dark
/// ? AppColors.xDark : AppColors.xLight` بكل شاشة على حدة.
///
/// ⚠️ ملاحظة صريحة: هذا يجعل الترحيل لدعم الوضع الليلي **ممكناً بسهولة**
/// شاشة بشاشة، لكنه لا "يكمل" الوضع الليلي تلقائياً بكل الشاشات —
/// المشروع فيه عشرات الشاشات تستخدم ألواناً ثابتة (`Colors.white`,
/// `Color(0xFFF8F9FA)`, إلخ) مباشرة بدل الثيم، وتحويل كل واحدة فعلياً
/// يحتاج مراجعة يدوية لكل شاشة (استبدال الألوان الثابتة بهذا الامتداد
/// أو بـ Theme.of(context) مباشرة). طُبِّق هذا الامتداد فعلياً على
/// أكثر شاشتين أهمية لإثبات عمل الوضع الليلي فعلياً (الرئيسية والإعدادات
/// حيث يعيش مفتاح التبديل نفسه)، والبقية تحتاج نفس المعالجة تدريجياً.
extension AdaptiveColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// خلفية الشاشة الرئيسية (بديل عن `Color(0xFFF8F9FA)`/`Colors.white` الثابتة)
  Color get adaptiveScaffoldBg => isDarkMode ? AppColors.bgDark : const Color(0xFFF8F9FA);

  /// خلفية البطاقات/الحاويات (بديل عن `Colors.white` الثابتة)
  Color get adaptiveCardBg => isDarkMode ? AppColors.surfaceDark2 : Colors.white;

  /// النص الأساسي
  Color get adaptiveTextPrimary => isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  /// النص الثانوي (عناوين فرعية، تلميحات)
  Color get adaptiveTextSecondary => isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  /// حدود خفيفة بين العناصر
  Color get adaptiveBorder => isDarkMode ? Colors.white24 : const Color(0xFFE5E7EB);
}
