import 'package:flutter/material.dart';
import 'package:mators_car/screens/adsCar/manage/manage_ads_screen.dart';

/// شاشة "إعلاناتي" الخاصة بحساب الفرد.
/// تُبنى فوق الشاشة المشتركة [ManageAdsScreen] التي تدير إعلانات
/// البيع والتأجير معاً (نفس الـ API يخدم الفرد والمعرض).
class IndividualAdsScreen extends StatelessWidget {
  const IndividualAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManageAdsScreen(title: 'إعلاناتي');
  }
}
