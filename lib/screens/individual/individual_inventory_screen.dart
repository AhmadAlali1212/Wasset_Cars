import 'package:flutter/material.dart';
import 'package:mators_car/screens/company/company_inventory_screen.dart';
import 'package:mators_car/screens/individual/individual_add_car_screen.dart';

/// شاشة "سياراتي" الخاصة بحساب الفرد.
/// تُبنى فوق نفس الشاشة المشتركة [CompanyInventoryScreen] التي يستخدمها
/// المعرض (نفس الـ API يخدم الفرد والمعرض)، بحيث يكون التصميم موحّداً
/// بين الحسابين — الفرق الوحيد هو شاشة إضافة السيارة (نموذج بسيط للفرد
/// مقابل معالج بعدة خطوات للمعرض).
class IndividualInventoryScreen extends StatelessWidget {
  const IndividualInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyInventoryScreen(
      title: 'سياراتي',
      emptyStateTitle: 'لم تتم إضافة سيارات بعد',
      emptyStateSubtitle: 'استخدم زر الإضافة لإدخال أول سيارة لك',
      emptyStateIcon: Icons.directions_car_filled_outlined,
      addCarScreenBuilder: (_) => const IndividualAddCarScreen(),
    );
  }
}
