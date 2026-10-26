import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/data/models/promotion_model.dart';
import 'package:mators_car/services/controllers/ads_service.dart';
import 'package:mators_car/services/controllers/auth_serivces.dart';
import 'package:mators_car/services/controllers/promotion_service.dart';
import 'package:mators_car/services/controllers/rental_ad_service.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';
import 'package:mators_car/widgets/promotions/promoted_cars_widgets.dart';

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

class _PromotedCarsScreenState extends State<PromotedCarsScreen> {
  final PromotionService _promotionService = PromotionService();
  final AdsService _adsService = AdsService();
  final RentalAdService _rentalAdService = RentalAdService();
  late Future<List<PromotedSection>> _sectionsFuture;
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

  Future<List<PromotedSection>> _fetchPromotedSections() async {
    final promotionsByOwner =
        await _promotionService.getActivePromotionsByOwner();
    if (promotionsByOwner.isEmpty) return [];

    final myUserId = int.tryParse('${_authService?.currentUser?['id'] ?? ''}');

    // كل الشركات التي عندها عرض نشط، باستثناء حسابي أنا (لو كنت شركة)
    final ownerIds =
        promotionsByOwner.keys
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

    final sections = <PromotedSection>[];
    for (var i = 0; i < ownerIds.length; i++) {
      final ownerId = ownerIds[i];
      final saleAds = saleResults[i].map((json) => Ad.fromJson(json)).toList();
      final rentalAds = rentalAdsByOwner[ownerId] ?? [];

      final combinedAds = <PromotedAd>[
        ...saleAds.map((ad) => PromotedAd(ad: ad, isRental: false)),
        ...rentalAds.map((ad) => PromotedAd(ad: ad, isRental: true)),
      ];
      if (combinedAds.isEmpty) continue;

      final promotion = promotionsByOwner[ownerId]!;
      final companyName =
          promotion.ownerName?.isNotEmpty == true
              ? promotion.ownerName!
              : (combinedAds.first.ad.sellerName.isNotEmpty
                  ? combinedAds.first.ad.sellerName
                  : combinedAds.first.ad.car.userName);

      sections.add(
        PromotedSection(
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

  List<PromotedSection> _applySearch(List<PromotedSection> sections) {
    if (_searchQuery.trim().isEmpty) return sections;
    final query = _searchQuery.toLowerCase();

    final filtered = <PromotedSection>[];
    for (final section in sections) {
      final companyMatches = section.companyName.toLowerCase().contains(query);
      final matchingAds =
          section.ads
              .where(
                (pa) => '${pa.ad.car.make} ${pa.ad.car.model}'
                    .toLowerCase()
                    .contains(query),
              )
              .toList();

      if (companyMatches) {
        filtered.add(section);
      } else if (matchingAds.isNotEmpty) {
        filtered.add(
          PromotedSection(
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
                child: FutureBuilder<List<PromotedSection>>(
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

                    final sections = List<PromotedSection>.from(
                      _applySearch(snapshot.data ?? const <PromotedSection>[]),
                    );

                    if (_sortMode == 'most_cars') {
                      sections.sort(
                        (a, b) => b.ads.length.compareTo(a.ads.length),
                      );
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
                        return PromotedSectionView(section: sections[index]);
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
}
