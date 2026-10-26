import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';

/// ودجات استُخرجت من دوال _build... الخاصة بـ sale_ads_list.dart دون أي
/// تغيير بالتصميم أو المنطق.

/// صف شرائح فلترة أفقي حسب حالة الإعلان (نشطة/منتهية/الكل).
class SaleAdsStatusFilterChips extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onSelect;

  const SaleAdsStatusFilterChips({super.key, required this.selectedStatus, required this.onSelect});

  static const List<Map<String, String>> _filters = [
    {'key': 'active', 'label': 'إعلانات نشطة'},
    {'key': 'expired', 'label': 'إعلانات منتهية'},
    {'key': 'all', 'label': 'الكل'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = selectedStatus == filter['key'];
          return ChoiceChip(
            label: Text(filter['label']!),
            selected: selected,
            onSelected: (_) => onSelect(filter['key']!),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: context.adaptiveCardBg,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300),
            ),
          );
        },
      ),
    );
  }
}

/// حالة عدم وجود أي إعلانات بيع للمستخدم إطلاقاً.
class SaleAdsEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const SaleAdsEmptyState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, size: 70, color: Colors.grey),
                SizedBox(height: 14),
                Text('لا توجد إعلانات بيع بعد'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة عدم وجود إعلانات ضمن الفلتر الحالي (لكن توجد إعلانات في أقسام أخرى).
class SaleAdsFilteredEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const SaleAdsFilteredEmptyState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox(height: 100), Center(child: Text('لا توجد إعلانات في هذا القسم'))],
      ),
    );
  }
}

/// بطاقة إعلان بيع واحد (صورة + عنوان + سعر + شارة حالة + قائمة إجراءات
/// + زر "تم البيع" ظاهر مباشرة عند إمكانية ذلك).
class SaleAdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final String Function(String?) translateStatus;
  final Color Function(String?) statusColor;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onMarkSold;
  final VoidCallback onDelete;

  const SaleAdCard({
    super.key,
    required this.ad,
    required this.translateStatus,
    required this.statusColor,
    required this.onEdit,
    required this.onPublish,
    required this.onMarkSold,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final price = ad['price']?.toString() ?? '-';
    final status = ad['status']?.toString();
    final car = ad['car'] is Map ? ad['car'] as Map : null;
    final carTitle = car != null ? '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim() : 'سيارة غير محددة';
    final images = car != null ? car['images'] : null;
    final imageUrl = images is List && images.isNotEmpty ? images.first.toString() : null;
    final canMarkSold = status == 'active' || status == 'approved';

    return Container(
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading:
                imageUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        placeholder: (_, __) => Container(width: 60, height: 60, color: const Color(0xFFF0F0F0)),
                        errorWidget: (_, __, ___) => const Icon(Icons.directions_car, size: 36),
                      ),
                    )
                    : const CircleAvatar(radius: 28, child: Icon(Icons.directions_car, size: 26)),
            title: Text(
              carTitle.isEmpty ? 'سيارة غير محددة' : carTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(child: Text('السعر: $price ل.س')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      translateStatus(status),
                      style: TextStyle(fontSize: 11, color: statusColor(status), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'publish') {
                  onPublish();
                } else if (value == 'sold') {
                  onMarkSold();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder:
                  (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل السعر')),
                    if (status != 'active' && status != 'approved')
                      const PopupMenuItem(value: 'publish', child: Text('نشر الإعلان')),
                    if (status == 'active' || status == 'approved')
                      const PopupMenuItem(
                        value: 'sold',
                        child: Text('تم البيع ✅', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ),
                    const PopupMenuItem(value: 'delete', child: Text('حذف الإعلان')),
                  ],
            ),
          ),
          // زر "تم البيع" ظاهر ومباشر بدل الاكتفاء بقائمة الخيارات فقط،
          // ليكون واضحاً وسهل الوصول لصاحب الإعلان
          if (canMarkSold)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMarkSold,
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                  label: const Text('تم البيع', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// قائمة إعلانات البيع بعد الفلترة (أو رسالة الخطأ/الفراغ المناسبة).
class SaleAdsListView extends StatelessWidget {
  final List<Map<String, dynamic>> ads;
  final Future<void> Function() onRefresh;
  final String Function(String?) translateStatus;
  final Color Function(String?) statusColor;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onPublish;
  final void Function(Map<String, dynamic>) onMarkSold;
  final void Function(Map<String, dynamic>) onDelete;

  const SaleAdsListView({
    super.key,
    required this.ads,
    required this.onRefresh,
    required this.translateStatus,
    required this.statusColor,
    required this.onEdit,
    required this.onPublish,
    required this.onMarkSold,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ad = ads[index];
          return SaleAdCard(
            ad: ad,
            translateStatus: translateStatus,
            statusColor: statusColor,
            onEdit: () => onEdit(ad),
            onPublish: () => onPublish(ad),
            onMarkSold: () => onMarkSold(ad),
            onDelete: () => onDelete(ad),
          );
        },
      ),
    );
  }
}
