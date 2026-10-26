import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

/// ودجات استُخرجت من company_inventory_screen.dart دون أي تغيير بالتصميم
/// أو المنطق — فقط تقسيم الشاشة الكبيرة لملفات أصغر وأسهل قراءة.

/// شريط بحث موحّد الشكل أعلى شاشة المخزون.
class InventorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const InventorySearchBar({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.adaptiveCardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: context.tr('search_car'),
            hintStyle: TextStyle(color: context.adaptiveTextSecondary),
            prefixIcon: Icon(Icons.search, color: context.adaptiveTextSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// صف شرائح فلترة أفقي حسب حالة المراجعة (الكل/قيد المراجعة/مقبول/مرفوض).
class InventoryFilterChips extends StatelessWidget {
  final List<Map<String, String>> filters;
  final String? selectedStatus;
  final Color primaryColor;
  final ValueChanged<String?> onSelect;

  const InventoryFilterChips({
    super.key,
    required this.filters,
    required this.selectedStatus,
    required this.primaryColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedStatus == filter['key'];
          return ChoiceChip(
            label: Text(switch (filter['key']) {
              'pending' => context.tr('pending_review'),
              'approved' => context.tr('approved'),
              'rejected' => context.tr('rejected'),
              _ => context.tr('all'),
            }),
            selected: selected,
            onSelected: (_) => onSelect(filter['key']),
            showCheckmark: false,
            selectedColor: primaryColor,
            backgroundColor: context.adaptiveCardBg,
            labelStyle: TextStyle(
              color: selected ? Colors.white : context.adaptiveTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: selected ? primaryColor : const Color(0xFFE1E4EA)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          );
        },
      ),
    );
  }
}

/// حالة عدم وجود أي سيارات بالمخزون إطلاقاً (قبل أي فلترة/بحث).
class InventoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const InventoryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 70, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black45)),
        ],
      ),
    );
  }
}

/// بطاقة سيارة واحدة بمخزون المعرض (صورة + شارة حالة + مواصفات + أزرار
/// تعديل/فحص فني/حذف).
class InventoryCarCard extends StatelessWidget {
  final Map<String, dynamic> car;
  final String Function(String?) translateStatus;
  final Color Function(String?) getStatusColor;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onInspect;

  const InventoryCarCard({
    super.key,
    required this.car,
    required this.translateStatus,
    required this.getStatusColor,
    required this.imageUrl,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final make = car['make'] ?? car['name'] ?? 'غير محدد';
    final model = car['model'] ?? 'غير محدد';
    final year = car['year']?.toString() ?? '-';
    final rawCondition = car['condition'] ?? 'used';
    final conditionText = rawCondition == 'new' ? 'جديد' : 'أوتوماتيك';
    final status = (car['approval_status'] ?? car['status'] ?? 'pending').toString();
    final mileage = car['mileage']?.toString() ?? car['odometer']?.toString();
    final city = car['city'] ?? car['location'] ?? 'دمشق';
    final statusColor = getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة السيارة مع شارة الحالة وأيقونة المفضلة
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child:
                      imageUrl != null
                          ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            placeholder: (_, __) => Container(color: const Color(0xFFF0F0F0)),
                            errorWidget:
                                (_, __, ___) => Container(
                                  color: const Color(0xFFF0F0F0),
                                  child: const Icon(
                                    Icons.directions_car,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                          : Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                          ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      translateStatus(status),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border, size: 18, color: Colors.black54),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$make $model $year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Row(
                        children: [
                          Text(city, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(width: 3),
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.black38),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(year, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      if (mileage != null)
                        Row(
                          children: [
                            const Icon(Icons.speed_outlined, size: 14, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text('$mileage كم', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      Row(
                        children: [
                          const Icon(Icons.settings_outlined, size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(conditionText, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF14245C)),
                        label: const Text('تعديل', style: TextStyle(color: Color(0xFF14245C))),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      ),
                      if (onInspect != null)
                        TextButton.icon(
                          onPressed: onInspect,
                          icon: const Icon(Icons.health_and_safety_outlined, size: 16, color: Colors.teal),
                          label: const Text('فحص فني', style: TextStyle(color: Colors.teal)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        ),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('حذف', style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة سيارات المخزون بعد الفلترة (أو رسالة "لا توجد نتائج مطابقة").
class InventoryCarsList extends StatelessWidget {
  final List<Map<String, dynamic>> cars;
  final Future<void> Function() onRefresh;
  final String? Function(Map<String, dynamic>) imageUrlFor;
  final String Function(String?) translateStatus;
  final Color Function(String?) getStatusColor;
  final void Function(Map<String, dynamic>) onTapCar;
  final void Function(Map<String, dynamic>) onEditCar;
  final void Function(Map<String, dynamic>) onDeleteCar;
  final void Function(Map<String, dynamic>)? onInspectCar;

  const InventoryCarsList({
    super.key,
    required this.cars,
    required this.onRefresh,
    required this.imageUrlFor,
    required this.translateStatus,
    required this.getStatusColor,
    required this.onTapCar,
    required this.onEditCar,
    required this.onDeleteCar,
    this.onInspectCar,
  });

  @override
  Widget build(BuildContext context) {
    if (cars.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج مطابقة للبحث/الفلتر',
          style: TextStyle(fontSize: 15, color: Colors.black45),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: cars.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final car = cars[index];
          return InventoryCarCard(
            car: car,
            translateStatus: translateStatus,
            getStatusColor: getStatusColor,
            imageUrl: imageUrlFor(car),
            onTap: () => onTapCar(car),
            onEdit: () => onEditCar(car),
            onDelete: () => onDeleteCar(car),
            onInspect: onInspectCar == null ? null : () => onInspectCar!(car),
          );
        },
      ),
    );
  }
}
