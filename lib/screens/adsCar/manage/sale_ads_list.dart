import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/screens/adsCar/manage/add_sale_ad_screen.dart';
import 'package:mators_car/services/ads_service.dart';
import 'package:mators_car/ulits/colors.dart';

/// عنصر واجهة قابل لإعادة الاستخدام يعرض إعلانات البيع الخاصة بالمستخدم
/// (فردي أو معرض) مع إمكانية: نشر الإعلان، تعديل السعر، حذف الإعلان.
class SaleAdsList extends StatefulWidget {
  const SaleAdsList({super.key});

  @override
  State<SaleAdsList> createState() => _SaleAdsListState();
}

class _SaleAdsListState extends State<SaleAdsList> {
  final AdsService _adsService = AdsService();
  late Future<List<Map<String, dynamic>>> _adsFuture;
  String _statusFilter = 'active'; // active | expired | all

  @override
  void initState() {
    super.initState();
    _adsFuture = _adsService.getMyAds();
  }

  Future<void> _refresh() async {
    setState(() {
      _adsFuture = _adsService.getMyAds();
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
      case 'draft':
        return 'مسودة (غير مسعّر)';
      case 'expired':
        return 'منتهي';
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
      case 'expired':
        return Colors.grey;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editAd(Map<String, dynamic> ad) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddSaleAdScreen(existingAd: ad)),
    );
    if (changed == true) _refresh();
  }

  Future<void> _publishAd(Map<String, dynamic> ad) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _adsService.publishAd(ad['id'] as int);
      await _refresh();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم نشر الإعلان بنجاح')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل نشر الإعلان: $e')),
      );
    }
  }

  // "تم البيع" — لا يوفّر الـ API حالياً حقل/endpoint حالة "مباع" منفصل عن
  // الحذف (لا يوجد PATCH لحالة الإعلان)، فآلية إتمام البيع بالكامل يدوية
  // خارج التطبيق (اتصال/واتساب مباشر مع المشتري كما في AdDetailScreen).
  // لذلك أقرب إجراء حقيقي متاح هو إزالة الإعلان من المعرض العام لأنه لم
  // يعد متاحاً، عبر نفس DELETE /my-ads/{id} المستخدم بالحذف، لكن بتسمية
  // ورسالة تأكيد مختلفة توضّح للبائع فعلياً ماذا سيحدث.
  Future<void> _markAsSold(Map<String, dynamic> ad) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('تأكيد البيع'),
            content: const Text(
              'بضغطك "تم البيع" ستتم إزالة هذا الإعلان من المعرض العام '
              'لأن السيارة لم تعد متاحة. لا تتوفر حالياً خاصية "مباع" '
              'منفصلة عن الحذف، ولا يمكن التراجع عن هذا الإجراء.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                  backgroundColor: AppColors.success,
                ),
                child: const Text('تم البيع'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await _adsService.deleteAd(ad['id'] as int);
      await _refresh();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل البيع وإزالة الإعلان من المعرض 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('تعذر تسجيل البيع: $e')),
      );
    }
  }

  Future<void> _deleteAd(Map<String, dynamic> ad) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('حذف الإعلان'),
            content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
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
      await _adsService.deleteAd(ad['id'] as int);
      await _refresh();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم حذف الإعلان بنجاح')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل حذف الإعلان: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _applyStatusFilter(
    List<Map<String, dynamic>> ads,
  ) {
    if (_statusFilter == 'all') return ads;
    if (_statusFilter == 'expired') {
      return ads.where((ad) => ad['status']?.toString() == 'expired').toList();
    }
    // 'active' يشمل أيضاً pending/rejected/draft (كل ما ليس منتهياً)
    // لأن هذا هو المكان الوحيد الذي تُدار منه إعلاناتي في التطبيق.
    return ads.where((ad) => ad['status']?.toString() != 'expired').toList();
  }

  Widget _buildStatusFilterChips() {
    final filters = const [
      {'key': 'active', 'label': 'إعلانات نشطة'},
      {'key': 'expired', 'label': 'إعلانات منتهية'},
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
                'تعذر جلب إعلانات البيع\n${snapshot.error}',
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
              final price = ad['price']?.toString() ?? '-';
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

              final canMarkSold = status == 'active' || status == 'approved';

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
                    child: Row(
                      children: [
                        Expanded(child: Text('السعر: $price ل.س')),
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
                      } else if (value == 'sold') {
                        _markAsSold(ad);
                      } else if (value == 'delete') {
                        _deleteAd(ad);
                      }
                    },
                    itemBuilder:
                        (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('تعديل السعر'),
                          ),
                          if (status != 'active' && status != 'approved')
                            const PopupMenuItem(
                              value: 'publish',
                              child: Text('نشر الإعلان'),
                            ),
                          if (status == 'active' || status == 'approved')
                            const PopupMenuItem(
                              value: 'sold',
                              child: Text(
                                'تم البيع ✅',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف الإعلان'),
                          ),
                        ],
                  ),
                    ),
                    // زر "تم البيع" ظاهر ومباشر بدل الاكتفاء بقائمة الخيارات
                    // فقط، ليكون واضحاً وسهل الوصول لصاحب الإعلان
                    if (canMarkSold)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _markAsSold(ad),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.success,
                            ),
                            label: const Text(
                              'تم البيع',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
            },
          ),
        );
      },
    );
  }
}
