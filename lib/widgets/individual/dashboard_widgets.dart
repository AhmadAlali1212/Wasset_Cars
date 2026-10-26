import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

/// ودجات استُخرجت من لوحة تحكم الفرد (individual_dashboard_screen.dart)
/// دون أي تغيير بالتصميم أو المنطق.

/// البطاقة الزرقاء العلوية: نوع الحساب + رسالة ترحيب + الرصيد الحالي.
class DashboardHeaderCard extends StatelessWidget {
  final String balance;
  final String currency;

  const DashboardHeaderCard({super.key, required this.balance, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F4C81), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('individual_account'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            context.tr('welcome_dashboard'),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '${context.tr('balance')}: $balance $currency',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// عنصر واحد بقائمة "أزرار الوصول السريع" (أيقونة + عنوان + وصف).
class DashboardActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const DashboardActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: context.adaptiveCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}

/// تنويه بعدم وجود أي سيارات منشورة عامة على المنصة بعد.
class DashboardEmptyCarsHint extends StatelessWidget {
  const DashboardEmptyCarsHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: context.adaptiveCardBg, borderRadius: BorderRadius.circular(18)),
      child: Text(context.tr('no_published_cars'), style: TextStyle(color: context.adaptiveTextSecondary)),
    );
  }
}

/// صف سيارة واحدة ضمن معاينة "كل السيارات المتوفرة" أسفل لوحة التحكم.
class DashboardAvailableCarTile extends StatelessWidget {
  final Map<String, dynamic> car;
  final String? imageUrl;
  final VoidCallback onTap;

  const DashboardAvailableCarTile({super.key, required this.car, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = '${car['make'] ?? ''} ${car['model'] ?? ''}';
    final year = car['year']?.toString() ?? '';
    final status = car['approval_status'] ?? car['status'] ?? 'غير معروف';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading:
            imageUrl != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    memCacheWidth: 140,
                    placeholder: (_, __) => Container(width: 70, height: 70, color: const Color(0xFFF0F0F0)),
                    errorWidget:
                        (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.directions_car, color: Colors.grey),
                        ),
                  ),
                )
                : Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.directions_car, color: Colors.grey),
                ),
        title: Text(title.trim().isEmpty ? context.tr('unspecified_car') : title),
        subtitle: Text('$year • ${context.tr('condition')}: $status'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
