import 'package:flutter/material.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/services/controllers/promotion_service.dart';
import 'package:mators_car/services/controllers/rental_ad_service.dart';

import 'package:mators_car/widgets/app_home_style_header.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/rental/rental_ads/rental_ads_widgets.dart';

class RentalAdsScreen extends StatefulWidget {
  const RentalAdsScreen({super.key});

  @override
  State<RentalAdsScreen> createState() => _RentalAdsScreenState();
}

class _RentalAdsScreenState extends State<RentalAdsScreen> {
  final RentalAdService _rentalAdService = RentalAdService();
  final PromotionService _promotionService = PromotionService();

  // بيانات حقيقية قادمة من API عبر GET /rental-ads (راجع قسم
  // "6. إدارة إعلانات التأجير (Rental Ads)" في ملف Postman) بدلاً من MockData.
  List<Ad> rentalAds = [];
  bool _isLoading = true;
  String? _errorMessage;

  // متغيرات منطق البحث وعرض الكل
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'newest'; // newest | price_asc | price_desc
  List<Ad>? _viewAllList;
  String? _viewAllTitle;

  // ⬅️ جديد: تحميل تدريجي حقيقي (Infinite Scroll) بدل جلب كل الصفحات
  // دفعة واحدة عند فتح الشاشة — نفس النمط المطبّق بالشاشة الرئيسية.
  static const int _pageSize = 20;
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  Set<int> _promotedOwnerIds = {};

  @override
  void initState() {
    super.initState();
    _loadRentalAds();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMoreRentalAds();
    }
  }

  Future<void> _loadRentalAds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      final rawAds = await _rentalAdService.getAllRentalAds(
        page: 1,
        perPage: _pageSize,
      );
      final ads = rawAds.map((json) => Ad.fromJson(json)).toList();

      // "مميز" هنا يعني: صاحب هذا الإعلان لديه عرض ترويجي نشط حالياً.
      // العرض الترويجي غير مرتبط بسيارة/إعلان محدد (راجع PromotionService)
      // بل بصاحب الحساب، لذلك يجب أن تظهر العلامة على كل إعلانات نفس
      // المالك وليس فقط على إعلان واحد أو أول عناصر عشوائية بالقائمة.
      Set<int> promotedOwnerIds = {};
      try {
        promotedOwnerIds = await _promotionService.getPromotedOwnerIds();
      } catch (_) {
        // تعذّر جلب العروض الترويجية (مثلاً بلا اتصال) لا يجب أن يمنع
        // عرض إعلانات التأجير نفسها، فقط لن تظهر علامة "مميز" مؤقتاً.
      }

      final withFeatured =
          ads
              .map(
                (ad) => ad.copyWith(
                  isFeatured: promotedOwnerIds.contains(ad.userId),
                ),
              )
              .toList();

      if (!mounted) return;
      setState(() {
        rentalAds = withFeatured;
        _promotedOwnerIds = promotedOwnerIds;
        _isLoading = false;
        _hasMorePages = rawAds.length >= _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر جلب إعلانات التأجير: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreRentalAds() async {
    if (_isLoadingMore || !_hasMorePages || _isLoading) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final rawAds = await _rentalAdService.getAllRentalAds(
        page: nextPage,
        perPage: _pageSize,
      );
      final newAds =
          rawAds
              .map((json) => Ad.fromJson(json))
              .map(
                (ad) => ad.copyWith(
                  isFeatured: _promotedOwnerIds.contains(ad.userId),
                ),
              )
              .toList();

      final existingIds = rentalAds.map((a) => a.id).toSet();

      if (!mounted) return;
      setState(() {
        rentalAds = [
          ...rentalAds,
          ...newAds.where((a) => !existingIds.contains(a.id)),
        ];
        _currentPage = nextPage;
        _hasMorePages = rawAds.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // دالة التنقل للتفاصيل
  void _navigateToDetail(Ad ad, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RentalAdDetailScreen(ad: ad)),
    );
  }

  // دالة تفعيل واجهة "عرض الكل"
  void _showAllAds(String title, List<Ad> ads) {
    setState(() {
      _viewAllTitle = title;
      _viewAllList = ads;
    });
  }

  double _parseDailyPrice(Ad ad) => double.tryParse(ad.dailyPrice) ?? 0;

  @override
  Widget build(BuildContext context) {
    // تصفية الإعلانات بناءً على نص البحث (البحث في الماركة أو الموديل)
    final filteredAds =
        rentalAds.where((ad) {
          final fullName = '${ad.car.make} ${ad.car.model}'.toLowerCase();
          return fullName.contains(_searchQuery.toLowerCase());
        }).toList();

    // تطبيق الترتيب المختار فعلياً من زر التصنيف (كان شكلياً بدون تأثير)
    switch (_sortMode) {
      case 'price_asc':
        filteredAds.sort(
          (a, b) => _parseDailyPrice(a).compareTo(_parseDailyPrice(b)),
        );
        break;
      case 'price_desc':
        filteredAds.sort(
          (a, b) => _parseDailyPrice(b).compareTo(_parseDailyPrice(a)),
        );
        break;
      default:
        filteredAds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final featuredAds = filteredAds.where((ad) => ad.isFeatured).toList();

    // واجهة "عرض الكل" في حال تم الضغط عليها
    if (_viewAllList != null) {
      return RentalAdsViewAll(
        title: _viewAllTitle ?? context.tr('rental_ads'),
        ads: _viewAllList!,
        onBack:
            () => setState(() {
              _viewAllList = null;
              _viewAllTitle = null;
            }),
      );
    }

    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              AppHomeStyleHeader(
                title: context.tr('rental_cars_ads'),
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                searchHint: context.tr('search_rental_cars'),
                onFilterTap: _showSortSheet,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RentalAdsBody(
                  rentalAds: rentalAds,
                  filteredAds: filteredAds,
                  featuredAds: featuredAds,
                  searchQuery: _searchQuery,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  isLoadingMore: _isLoadingMore,
                  hasMorePages: _hasMorePages,
                  scrollController: _scrollController,
                  onRefresh: _loadRentalAds,
                  onViewAll: _showAllAds,
                  onAdTap: (ad) => _navigateToDetail(ad, context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // زر التصنيف/التصفية — أصبح يطبّق الترتيب فعلياً على القائمة (كان شكلياً
  // يعرض رسالة تأكيد فقط دون أي تأثير حقيقي على النتائج).
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => RentalAdsSortSheet(
            selectedMode: _sortMode,
            onSelected: (mode) {
              setState(() => _sortMode = mode);
              Navigator.pop(context);
            },
          ),
    );
  }
}
