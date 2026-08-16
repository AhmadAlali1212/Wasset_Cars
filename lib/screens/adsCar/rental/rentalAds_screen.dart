import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/services/rental_ad_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';
import 'package:mators_car/widgets/section_header.dart';

class RentalAdsScreen extends StatefulWidget {
  const RentalAdsScreen({super.key});

  @override
  State<RentalAdsScreen> createState() => _RentalAdsScreenState();
}

class _RentalAdsScreenState extends State<RentalAdsScreen> {
  final RentalAdService _rentalAdService = RentalAdService();

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

  @override
  void initState() {
    super.initState();
    _loadRentalAds();
  }

  Future<void> _loadRentalAds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawAds = await _rentalAdService.getAllRentalAds();
      final ads = rawAds.map((json) => Ad.fromJson(json)).toList();

      // لا يوفر الـ API حقل "مميز" صريح لإعلانات التأجير، لذلك نضع علامة
      // "مميز" من طرف التطبيق على أول 5 إعلانات فقط لأغراض العرض.
      final withFeatured = List<Ad>.generate(ads.length, (index) {
        return index < 5 ? ads[index].copyWith(isFeatured: true) : ads[index];
      });

      if (!mounted) return;
      setState(() {
        rentalAds = withFeatured;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر جلب إعلانات التأجير: $e';
        _isLoading = false;
      });
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          title: Text(_viewAllTitle ?? 'إعلانات التأجير'),
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
              child: _buildRentalAdCard(_viewAllList![index], context),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              AppHomeStyleHeader(
                title: 'إعلانات تأجير السيارات',
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                searchHint: 'ابحث عن سيارة للتأجير...',
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
              const Text(
                'تصفية الإعلانات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('الأحدث'),
                trailing: _sortMode == 'newest' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'newest');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('الأقل سعرًا'),
                trailing:
                    _sortMode == 'price_asc' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'price_asc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money_outlined),
                title: const Text('الأعلى سعرًا'),
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
      return const Center(child: CircularProgressIndicator());
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 1. قسم الإعلانات المميزة (يختفي أثناء البحث لتسهيل تجربة المستخدم)
          if (_searchQuery.isEmpty && featuredAds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title: 'إعلانات مميزة',
                onViewAll:
                    () => _showAllAds(
                      'إعلانات مميزة',
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
                    child: _buildFeaturedRentalCard(
                      featuredAds[index],
                      context,
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
              title: 'جميع إعلانات التأجير',
              onViewAll: () => _showAllAds('جميع إعلانات التأجير', rentalAds),
            ),
          ),
          const SizedBox(height: 12),

          filteredAds.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('لا توجد نتائج تطابق بحثك'),
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
                    child: _buildRentalAdCard(filteredAds[index], context),
                  );
                },
              ),
        ],
      ),
    );
  }

  // الكرت المميز الكبير (مطابق للصورة تماماً بمقاييس الكود الخاص بك)
  Widget _buildFeaturedRentalCard(Ad ad, BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(ad, context),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: _buildImageWidget(
                    ad.car.images.isNotEmpty ? ad.car.images[0] : null,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'مميز',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 12,
                  left: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '1 / ${ad.car.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ل.س ${ad.dailyPrice} / يوم',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ad.car.location,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'أو ل.س ${ad.monthlyPrice} / شهر',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          ad.status == 'pending'
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ad.status == 'pending' ? 'قيد المراجعة' : 'متوفر',
                      style: TextStyle(
                        color:
                            ad.status == 'pending'
                                ? AppColors.warning
                                : AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الكرت الصغير الأفقي لـ "جميع إعلانات التأجير" (مطابق للصورة)
  Widget _buildRentalAdCard(Ad ad, BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(ad, context),
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: _buildImageWidget(
                    ad.car.images.isNotEmpty ? ad.car.images[0] : null,
                    width: 130,
                    height: 115,
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 12,
                    child: Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '1 / ${ad.car.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            ad.car.location,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ل.س ${ad.dailyPrice} / يوم',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'أو ل.س ${ad.monthlyPrice} / شهر',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                ad.status == 'pending'
                                    ? AppColors.warning.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ad.status == 'pending' ? 'قيد المراجعة' : 'متوفر',
                            style: TextStyle(
                              color:
                                  ad.status == 'pending'
                                      ? AppColors.warning
                                      : AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // نحدد حجم فك الترميز حسب عرض العرض الفعلي إن كان معروفاً، بحد
        // أقصى معقول، بدل تحميل الصورة الأصلية كاملة دائماً.
        memCacheWidth:
            (width != null && width.isFinite) ? (width * 2).round() : 600,
        placeholder: (context, url) => Container(color: Colors.grey.shade200),
        errorWidget: (context, url, error) {
          return Image.asset(
            'assets/image/intro.jpg',
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }
    return Image.asset(
      'assets/image/intro.jpg',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
