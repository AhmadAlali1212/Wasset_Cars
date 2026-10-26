import 'package:flutter/material.dart';
import 'package:mators_car/screens/adsCar/manage/add_sale_ad_screen.dart';
import 'package:mators_car/services/controllers/ads_service.dart';
import 'package:mators_car/services/controllers/user_search_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/manage-adsCar/sale_ads_list_widgets.dart';

/// عنصر واجهة قابل لإعادة الاستخدام يعرض إعلانات البيع الخاصة بالمستخدم
/// (فردي أو معرض) مع إمكانية: نشر الإعلان، تعديل السعر، حذف الإعلان.
class SaleAdsList extends StatefulWidget {
  const SaleAdsList({super.key});

  @override
  State<SaleAdsList> createState() => _SaleAdsListState();
}

class _SaleAdsListState extends State<SaleAdsList> {
  final AdsService _adsService = AdsService();
  final UserSearchService _userSearchService = UserSearchService();
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
        return context.tr('published');
      case 'pending':
        return context.tr('pending_review');
      case 'rejected':
        return context.tr('rejected');
      case 'draft':
        return context.tr('draft_unpriced');
      case 'expired':
        return context.tr('expired');
      default:
        return status ?? context.tr('unknown');
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
    try {
      await _adsService.publishAd(ad['id'] as int);
      await _refresh();
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: context.tr('ad_published'));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: context.tr('publish_ad_failed'),
        debugMessage: e,
      );
    }
  }

  // ⬅️ استبدال حل الحذف الالتفافي القديم بـ /my-ads/{id}/mark-sold الحقيقي
  // الذي يحتفظ بالسجل بدل حذفه، مع اختيار اختياري للمشتري الفعلي (بحث
  // بالاسم/الهاتف عبر /users/search) لتفعيل نظام التقييم بعدها.
  Future<void> _markAsSold(Map<String, dynamic> ad) async {
    final selectedBuyer = await _pickBuyerDialog();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('confirm_sale')),
            content: Text(
              selectedBuyer != null
                  ? 'سيتم تعليم هذا الإعلان كـ "مباع" وربطه بالمشتري '
                      '"${selectedBuyer['name']}"، ليصبح بإمكان الطرفين تقييم بعضهما لاحقاً.'
                  : 'سيتم تعليم هذا الإعلان كـ "مباع". يبقى سجل الإعلان محفوظاً '
                      '(لن يُحذف)، لكن دون ربط بمشتري محدد.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.success,
                ),
                child: Text(context.tr('sold')),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await _adsService.markSold(
        ad['id'] as int,
        buyerId:
            selectedBuyer != null ? (selectedBuyer['id'] as num).toInt() : null,
      );
      await _refresh();
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        title: context.tr('sale_recorded'),
        subtitle: context.tr('ad_saved_as_sold'),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر تسجيل البيع',
        debugMessage: e,
      );
    }
  }

  // بحث اختياري عن المشتري الفعلي؛ يعيد null إن تخطّى المستخدم الخطوة
  Future<Map<String, dynamic>?> _pickBuyerDialog() async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool isSearching = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> runSearch(String query) async {
              setDialogState(() => isSearching = true);
              try {
                final found = await _userSearchService.search(query);
                setDialogState(() {
                  results = found;
                  isSearching = false;
                });
              } catch (_) {
                setDialogState(() => isSearching = false);
              }
            }

            return AlertDialog(
              title: Text(context.tr('choose_buyer_optional')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: context.tr('search_buyer_hint'),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.trim().length >= 2) runSearch(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (results.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final user = results[index];
                            return ListTile(
                              title: Text(user['name']?.toString() ?? ''),
                              subtitle: Text(
                                user['phone_number']?.toString() ?? '',
                              ),
                              onTap: () => Navigator.pop(dialogContext, user),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text(context.tr('skip_without_buyer')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAd(Map<String, dynamic> ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('delete_ad')),
            content: Text(context.tr('confirm_delete_ad')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.error,
                ),
                child: Text(context.tr('delete')),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await _adsService.deleteAd(ad['id'] as int);
      await _refresh();
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: context.tr('ad_deleted'));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: context.tr('delete_ad_failed'),
        debugMessage: e,
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

  Widget _buildStatusFilterChips() => SaleAdsStatusFilterChips(
        selectedStatus: _statusFilter,
        onSelect: (key) => setState(() => _statusFilter = key),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_buildStatusFilterChips(), Expanded(child: _buildList())],
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonList(itemCount: 6);
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
          return SaleAdsEmptyState(onRefresh: _refresh);
        }

        if (ads.isEmpty) {
          return SaleAdsFilteredEmptyState(onRefresh: _refresh);
        }

        return SaleAdsListView(
          ads: ads,
          onRefresh: _refresh,
          translateStatus: _translateStatus,
          statusColor: _statusColor,
          onEdit: _editAd,
          onPublish: _publishAd,
          onMarkSold: _markAsSold,
          onDelete: _deleteAd,
        );
      },
    );
  }
}
