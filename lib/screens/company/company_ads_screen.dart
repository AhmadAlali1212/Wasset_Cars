import 'package:flutter/material.dart';
import 'package:mators_car/screens/adsCar/manage/manage_ads_screen.dart';
import 'package:mators_car/screens/company/company_bulk_pricing_screen.dart';
import 'package:mators_car/screens/company/company_bulk_upload_screen.dart';

/// شاشة "إعلانات المعرض" الخاصة بحساب المعرض (Company).
/// تُبنى فوق الشاشة المشتركة [ManageAdsScreen] التي تدير إعلانات
/// البيع والتأجير معاً (نفس الـ API يخدم الفرد والمعرض)، وتضيف
/// زر "رفع جماعي" لإضافة عدة سيارات دفعة واحدة، وزر "تسعير جماعي"
/// لتسعير الإعلانات المسودة الناتجة عن الرفع الجماعي.
class CompanyAdsScreen extends StatelessWidget {
  const CompanyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManageAdsScreen(
      title: 'إعلانات المعرض',
      actions: [
        IconButton(
          tooltip: 'رفع سيارات جماعي',
          icon: const Icon(Icons.upload_file_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompanyBulkUploadScreen(),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'تسعير الإعلانات المسودة (رفع جماعي)',
          icon: const Icon(Icons.price_change_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompanyBulkPricingScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
