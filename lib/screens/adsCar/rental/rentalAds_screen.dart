import 'package:flutter/material.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/services/controllers/promotion_service.dart';
import 'package:mators_car/services/controllers/rental_ad_service.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';
import 'package:mators_car/widgets/section_header.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/widgets/sellCars/home_common_widgets.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/rental/rental_ads/rental_ad_cards.dart';

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
      return Scaffold(
        appBar: AppBar(
          title: Text(_viewAllTitle ?? context.tr('rental_ads')),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                () => setState(() {
                  _viewAllList = null;
                  _viewAllTitle = null;
                }),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _viewAllList!.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RentalAdCard(
                ad: _viewAllList![index],
                onTap: () => _navigateToDetail(_viewAllList![index], context),
              ),
            );
          },
        ),
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
              Expanded(child: _buildBody(filteredAds, featuredAds)),
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
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('filter_ads'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort),
                title: Text(context.tr('newest')),
                trailing:
                    _sortMode == 'newest' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'newest');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(context.tr('lowest_price')),
                trailing:
                    _sortMode == 'price_asc' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'price_asc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money_outlined),
                title: Text(context.tr('highest_price')),
                trailing:
                    _sortMode == 'price_desc' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'price_desc');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(List<Ad> filteredAds, List<Ad> featuredAds) {
    if (_isLoading) {
      return const SkeletonCarGrid(itemCount: 6);
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadRentalAds,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRentalAds,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 1. قسم الإعلانات المميزة (يختفي أثناء البحث لتسهيل تجربة المستخدم)
          if (_searchQuery.isEmpty && featuredAds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title: context.tr('featured_ads'),
                onViewAll:
                    () => _showAllAds(
                      context.tr('featured_ads'),
                      rentalAds.where((ad) => ad.isFeatured).toList(),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height:
                  290, // زيادة الارتفاع ليتناسب مع أبعاد التصميم الجديد المرفق بالصورة
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: featuredAds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: FeaturedRentalCard(
                      ad: featuredAds[index],
                      onTap:
                          () => _navigateToDetail(featuredAds[index], context),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. جميع إعلانات التأجير
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: context.tr('all_rental_ads'),
              onViewAll:
                  () => _showAllAds(context.tr('all_rental_ads'), rentalAds),
            ),
          ),
          const SizedBox(height: 12),

          filteredAds.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(context.tr('no_matching_results')),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredAds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RentalAdCard(
                      ad: filteredAds[index],
                      onTap:
                          () => _navigateToDetail(filteredAds[index], context),
                    ),
                  );
                },
              ),
          // ⬅️ جديد: مؤشر تحميل الصفحة التالية (Infinite Scroll)
          if (_searchQuery.isEmpty)
            LoadMoreFooter(
              isLoadingMore: _isLoadingMore,
              hasMorePages: _hasMorePages,
              showEndMessage: rentalAds.isNotEmpty,
            ),
        ],
      ),
    );
  }
}
