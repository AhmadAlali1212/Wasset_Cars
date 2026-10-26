import 'package:flutter/material.dart';
import 'package:mators_car/screens/adsCar/manage/manage_ads_screen.dart';
import 'package:mators_car/screens/company/company_bulk_pricing_screen.dart';
import 'package:mators_car/screens/company/company_bulk_upload_screen.dart';
import 'package:mators_car/screens/company/company_excel_bulk_upload_screen.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

/// شاشة "إعلانات المعرض" الخاصة بحساب المعرض (Company).
/// تُبنى فوق الشاشة المشتركة [ManageAdsScreen] التي تدير إعلانات
/// البيع والتأجير معاً (نفس الـ API يخدم الفرد والمعرض)، وتضيف قائمة
/// "رفع جماعي" (Excel الرسمي عبر السيرفر، أو إدخال يدوي بديل)، وزر
/// "تسعير جماعي" لتسعير الإعلانات المسودة الناتجة عن الرفع عبر Excel.
class CompanyAdsScreen extends StatelessWidget {
  const CompanyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManageAdsScreen(
      title: context.tr('company_ads'),
      actions: [
        PopupMenuButton<String>(
          tooltip: context.tr('bulk_upload_title'),
          icon: const Icon(Icons.upload_file_outlined),
          onSelected: (value) {
            if (value == 'excel') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompanyExcelBulkUploadScreen(),
                ),
              );
            } else if (value == 'manual') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompanyBulkUploadScreen(),
                ),
              );
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'excel',
                  child: Text(context.tr('upload_excel_recommended')),
                ),
                PopupMenuItem(
                  value: 'manual',
                  child: Text(context.tr('manual_entry')),
                ),
              ],
        ),
        IconButton(
          tooltip: context.tr('bulk_pricing_tooltip'),
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
