import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/screens/adsCar/manage/add_rental_ad_screen.dart';
import 'package:mators_car/services/rental_ad_service.dart';
import 'package:mators_car/ulits/colors.dart';

/// عنصر واجهة قابل لإعادة الاستخدام يعرض إعلانات التأجير الخاصة بالمستخدم
/// (فردي أو معرض) مع إمكانية: نشر الإعلان، تعديل بياناته، حذف الإعلان.
class RentalAdsList extends StatefulWidget {
  const RentalAdsList({super.key});

  @override
  State<RentalAdsList> createState() => _RentalAdsListState();
}

class _RentalAdsListState extends State<RentalAdsList> {
  final RentalAdService _rentalAdService = RentalAdService();
  late Future<List<Map<String, dynamic>>> _adsFuture;
  String _statusFilter = 'active'; // active | inactive | all

  @override
  void initState() {
    super.initState();
    _adsFuture = _rentalAdService.getMyRentalAds();
  }

  Future<void> _refresh() async {
    setState(() {
      _adsFuture = _rentalAdService.getMyRentalAds();
    });
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'active':
      case 'approved':
        return 'منشور';
      case 'pending':
        return 'بانتظار المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return status ?? 'غير معروف';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  // إعلان التأجير لا تنتهي مدته تلقائياً (دائم إلى أن يُحذف)، فالفلترة هنا
  // بين "نشطة" (active/approved) و"غير نشطة" (كل الباقي) بدل "منتهية".
  List<Map<String, dynamic>> _applyStatusFilter(
    List<Map<String, dynamic>> ads,
  ) {
    if (_statusFilter == 'all') return ads;
    final isActive =
        (String? s) => s == 'active' || s == 'approved';
    if (_statusFilter == 'inactive') {
      return ads.where((ad) => !isActive(ad['status']?.toString())).toList();
    }
    return ads.where((ad) => isActive(ad['status']?.toString())).toList();
  }

  Widget _buildStatusFilterChips() {
    final filters = const [
      {'key': 'active', 'label': 'إعلانات نشطة'},
      {'key': 'inactive', 'label': 'غير نشطة'},
      {'key': 'all', 'label': 'الكل'},
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = _statusFilter == filter['key'];
          return ChoiceChip(
            label: Text(filter['label']!),
            selected: selected,
            onSelected: (_) => setState(() => _statusFilter = filter['key']!),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editAd(Map<String, dynamic> ad) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddRentalAdScreen(existingAd: ad)),
    );
    if (changed == true) _refresh();
  }

  Future<void> _publishAd(Map<String, dynamic> ad) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _rentalAdService.publishRentalAd(ad['id'] as int);
      await _refresh();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم نشر إعلان التأجير بنجاح')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل نشر إعلان التأجير: $e')),
      );
    }
  }

  Future<void> _deleteAd(Map<String, dynamic> ad) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('حذف إعلان التأجير'),
            content: const Text('هل أنت متأكد من حذف إعلان التأجير هذا؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                  backgroundColor: AppColors.error,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await _rentalAdService.deleteRentalAd(ad['id'] as int);
      await _refresh();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم حذف إعلان التأجير بنجاح')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل حذف إعلان التأجير: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatusFilterChips(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'تعذر جلب إعلانات التأجير\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final allAds = snapshot.data ?? [];
        final ads = _applyStatusFilter(allAds);
        if (allAds.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.car_rental_outlined, size: 70, color: Colors.grey),
                      SizedBox(height: 14),
                      Text('لا توجد إعلانات تأجير بعد'),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (ads.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text('لا توجد إعلانات في هذا القسم')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ad = ads[index];
              final dailyPrice =
                  (ad['daily_price'] ?? ad['dailyPrice'] ?? '-').toString();
              final monthlyPrice =
                  (ad['monthly_price'] ?? ad['monthlyPrice'] ?? '').toString();
              final status = ad['status']?.toString();
              final car = ad['car'] is Map ? ad['car'] as Map : null;
              final carTitle =
                  car != null
                      ? '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim()
                      : 'سيارة غير محددة';
              final images = car != null ? car['images'] : null;
              final imageUrl =
                  images is List && images.isNotEmpty
                      ? images.first.toString()
                      : null;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
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
                              placeholder:
                                  (_, __) => Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFFF0F0F0),
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(
                                    Icons.directions_car,
                                    size: 36,
                                  ),
                            ),
                          )
                          : const CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.directions_car, size: 26),
                          ),
                  title: Text(
                    carTitle.isEmpty ? 'سيارة غير محددة' : carTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('اليومي: $dailyPrice ل.س'
                            '${monthlyPrice.isNotEmpty && monthlyPrice != 'null' ? ' • الشهري: $monthlyPrice ل.س' : ''}'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _translateStatus(status),
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editAd(ad);
                      } else if (value == 'publish') {
                        _publishAd(ad);
                      } else if (value == 'delete') {
                        _deleteAd(ad);
                      }
                    },
                    itemBuilder:
                        (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('تعديل الإعلان'),
                          ),
                          if (status != 'active' && status != 'approved')
                            const PopupMenuItem(
                              value: 'publish',
                              child: Text('نشر الإعلان'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف الإعلان'),
                          ),
                        ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
