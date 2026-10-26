import 'package:flutter/material.dart';
import 'package:mators_car/screens/company/company_inventory_screen.dart';
import 'package:mators_car/screens/individual/individual_add_car_screen.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

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
      title: context.tr('my_cars'),
      emptyStateTitle: context.tr('no_cars_added_individual'),
      emptyStateSubtitle: context.tr('add_first_car_hint'),
      emptyStateIcon: Icons.directions_car_filled_outlined,
      addCarScreenBuilder: (_) => const IndividualAddCarScreen(),
    );
  }
}
