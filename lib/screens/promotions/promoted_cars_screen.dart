import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/models/promotion_model.dart';
import 'package:mators_car/services/ads_service.dart';
import 'package:mators_car/services/auth_serivces.dart';
import 'package:mators_car/services/promotion_service.dart';
import 'package:mators_car/services/rental_ad_service.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_detail_screen.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';

/// شاشة "سيارات العروض الترويجية" — بعكس شاشة إدارة العروض (CRUD)، هذه
/// الشاشة مخصصة لتصفح السيارات نفسها. بما أن العرض الترويجي بالـ API حملة
/// عامة تابعة للشركة وليست مرتبطة بسيارة محددة (لا يوجد car_id/ad_id على
/// العرض)، فكل عرض يشمل تلقائياً كل سيارات الشركة صاحبة العرض: نجلب لكل
/// شركة لديها عرض نشط كل إعلاناتها (وليس فقط أول صفحة من كل السوق)، ونعرض
/// سياراتها مجمّعة تحت بطاقة عرضها الترويجي.
class PromotedCarsScreen extends StatefulWidget {
  const PromotedCarsScreen({super.key});

  @override
  State<PromotedCarsScreen> createState() => _PromotedCarsScreenState();
}

class _PromotedAd {
  final Ad ad;
  final bool isRental;
  _PromotedAd({required this.ad, required this.isRental});
}

class _PromotedSection {
  final Promotion promotion;
  final String companyName;
  final List<_PromotedAd> ads;
  _PromotedSection({
    required this.promotion,
    required this.companyName,
    required this.ads,
  });
}

class _PromotedCarsScreenState extends State<PromotedCarsScreen> {
  final PromotionService _promotionService = PromotionService();
  final AdsService _adsService = AdsService();
  final RentalAdService _rentalAdService = RentalAdService();
  late Future<List<_PromotedSection>> _sectionsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'ending_soon'; // ending_soon | most_cars

  @override
  void initState() {
    super.initState();
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _authService = Provider.of<AuthService>(context, listen: false);
      _load();
    }
  }

  void _load() {
    _sectionsFuture = _fetchPromotedSections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // زر التصنيف — يطبّق ترتيباً فعلياً على أقسام الشركات المعروضة
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
                'تصفية العروض',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('الأقرب لانتهاء العرض'),
                trailing:
                    _sortMode == 'ending_soon' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'ending_soon');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car),
                title: const Text('الأكثر سيارات'),
                trailing:
                    _sortMode == 'most_cars' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'most_cars');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<_PromotedSection>> _fetchPromotedSections() async {
    final promotionsByOwner = await _promotionService
        .getActivePromotionsByOwner();
    if (promotionsByOwner.isEmpty) return [];

    final myUserId = int.tryParse('${_authService?.currentUser?['id'] ?? ''}');

    // كل الشركات التي عندها عرض نشط، باستثناء حسابي أنا (لو كنت شركة)
    final ownerIds = promotionsByOwner.keys
        .where((id) => myUserId == null || id != myUserId)
        .toList();
    if (ownerIds.isEmpty) return [];

    // العرض الترويجي حملة عامة تشمل كل سيارات صاحبها بغض النظر عن نوع
    // الإعلان (بيع أو تأجير)، لذلك نجلب النوعين معاً: كل سيارات البيع
    // لكل شركة على حدة (userId مدعوم بـ GET /ads)، وكل إعلانات التأجير
    // مرة واحدة فقط (لا يدعم GET /rental-ads فلترة بصاحب الإعلان) ثم
    // نُصفّيها محلياً حسب كل شركة.
    final saleResultsFuture = Future.wait(
      ownerIds.map(
        (ownerId) => _adsService.getAllAds(
          status: 'active',
          userId: ownerId,
          perPage: 100,
        ),
      ),
    );
    final rentalResultsFuture = _rentalAdService.getAllRentalAds();

    final saleResults = await saleResultsFuture;
    List<Map<String, dynamic>> rentalResultsRaw = [];
    try {
      rentalResultsRaw = await rentalResultsFuture;
    } catch (_) {
      // تعذّر جلب إعلانات التأجير لا يجب أن يمنع ظهور سيارات البيع
      // الترويجية على الأقل.
    }
    final rentalAdsByOwner = <int, List<Ad>>{};
    for (final json in rentalResultsRaw) {
      final ad = Ad.fromJson(json);
      rentalAdsByOwner.putIfAbsent(ad.userId, () => []).add(ad);
    }

    final sections = <_PromotedSection>[];
    for (var i = 0; i < ownerIds.length; i++) {
      final ownerId = ownerIds[i];
      final saleAds = saleResults[i].map((json) => Ad.fromJson(json)).toList();
      final rentalAds = rentalAdsByOwner[ownerId] ?? [];

      final combinedAds = <_PromotedAd>[
        ...saleAds.map((ad) => _PromotedAd(ad: ad, isRental: false)),
        ...rentalAds.map((ad) => _PromotedAd(ad: ad, isRental: true)),
      ];
      if (combinedAds.isEmpty) continue;

      final promotion = promotionsByOwner[ownerId]!;
      final companyName = promotion.ownerName?.isNotEmpty == true
          ? promotion.ownerName!
          : (combinedAds.first.ad.sellerName.isNotEmpty
                ? combinedAds.first.ad.sellerName
                : combinedAds.first.ad.car.userName);

      sections.add(
        _PromotedSection(
          promotion: promotion,
          companyName: companyName,
          ads: combinedAds,
        ),
      );
    }

    // الأقرب انتهاءً أولاً، لإبراز العروض التي توشك على الانتهاء
    sections.sort((a, b) {
      final aEnd = a.promotion.endDate;
      final bEnd = b.promotion.endDate;
      if (aEnd == null || bEnd == null) return 0;
      return aEnd.compareTo(bEnd);
    });

    return sections;
  }

  AuthService? _authService;

  Future<void> _refresh() async {
    setState(_load);
    await _sectionsFuture;
  }

  List<_PromotedSection> _applySearch(List<_PromotedSection> sections) {
    if (_searchQuery.trim().isEmpty) return sections;
    final query = _searchQuery.toLowerCase();

    final filtered = <_PromotedSection>[];
    for (final section in sections) {
      final companyMatches = section.companyName.toLowerCase().contains(
        query,
      );
      final matchingAds = section.ads
          .where(
            (pa) => '${pa.ad.car.make} ${pa.ad.car.model}'.toLowerCase().contains(
              query,
            ),
          )
          .toList();

      if (companyMatches) {
        filtered.add(section);
      } else if (matchingAds.isNotEmpty) {
        filtered.add(
          _PromotedSection(
            promotion: section.promotion,
            companyName: section.companyName,
            ads: matchingAds,
          ),
        );
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: AppHomeStyleHeader(
                title: 'العروض الترويجية',
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                searchHint: 'ابحث عن سيارة أو شركة عليها عرض...',
                onFilterTap: _showSortSheet,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<_PromotedSection>>(
                future: _sectionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            'تعذر جلب العروض\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  final sections = List<_PromotedSection>.from(
                    _applySearch(snapshot.data ?? const <_PromotedSection>[]),
                  );

                  if (_sortMode == 'most_cars') {
                    sections.sort((a, b) => b.ads.length.compareTo(a.ads.length));
                  } else {
                    sections.sort((a, b) {
                      final aEnd = a.promotion.endDate;
                      final bEnd = b.promotion.endDate;
                      if (aEnd == null || bEnd == null) return 0;
                      return aEnd.compareTo(bEnd);
                    });
                  }

                  if (sections.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Icon(
                            Icons.local_offer_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'لا توجد سيارات عليها عروض ترويجية حالياً',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      return _buildSection(sections[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSection(_PromotedSection section) {
    final promo = section.promotion;
    final discountLabel = promo.type == 'discount'
        ? 'خصم ${promo.value.toStringAsFixed(0)}%'
        : promo.value.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        promo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    discountLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F4C81),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                promo.isExpired
                    ? 'انتهى العرض'
                    : 'ينتهي خلال ${promo.daysRemaining} يوم',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.directions_car,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                '${section.ads.length} سيارة',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.ads.length,
            itemBuilder: (context, index) {
              final promotedAd = section.ads[index];
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SizedBox(
                  width: 150,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  promotedAd.isRental
                                      ? RentalAdDetailScreen(ad: promotedAd.ad)
                                      : AdDetailScreen(ad: promotedAd.ad),
                        ),
                      );
                    },
                    child: _buildCarCard(promotedAd),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard(_PromotedAd promotedAd) {
    final ad = promotedAd.ad;
    final car = ad.car;
    final priceText =
        promotedAd.isRental ? '${ad.dailyPrice} ل.س / يوم' : '${ad.price} ل.س';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  top: Radius.circular(16),
                ),
                child: car.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: car.images[0],
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 350,
                        placeholder: (context, url) => Container(
                          height: 110,
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/image/intro.jpg',
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/image/intro.jpg',
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'عليه عرض',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${car.make} ${car.model} ${car.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
