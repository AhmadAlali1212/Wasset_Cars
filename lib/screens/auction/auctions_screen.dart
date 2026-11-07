import 'package:flutter/material.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/services/controllers/auction_service.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'auction_detail_screen.dart';
import 'package:mators_car/widgets/autction/auctions_screen_widgets.dart';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  final AuctionService _auctionService = AuctionService();
  late Future<List<Auction>> _auctionsFuture;

  // الفلاتر العلوية
  String _filter = 'active';
  final List<Map<String, String>> _filters = [
    {'title': 'نشطة', 'value': 'active'},
    {'title': 'قادمة', 'value': 'upcoming'},
    {'title': 'منتهية', 'value': 'ended'},
  ];

  // متغيرات حالة البحث والتصفية
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'ending_soon'; // ending_soon | price_asc | price_desc

  @override
  void initState() {
    super.initState();
    _loadAuctions();
  }

  void _loadAuctions() {
    _auctionsFuture = _loadAllAuctions();
  }

  // GET /auctions يعرض active فقط افتراضياً، فتبويبا "قادمة" و"منتهية" كانا
  // يُطبَّقان محلياً على بيانات نشطة فقط ما يجعلهما فارغين دائماً. القيم
  // الموثّقة لفلتر status هي: pending, active, closed, cancelled + 'ended'
  // احتياطاً (استُخدمت فعلياً لاختبار حالة مزاد منتهٍ).
  Future<List<Auction>> _loadAllAuctions() async {
    // مهم جداً: لا يوجد حالياً أي مجدول (cron/scheduler) في السيرفر يستدعي
    // POST /auctions/close-expired تلقائياً، فالمزادات المنتهية زمنياً تبقى
    // status=active للأبد بدون فائز محدد — وهذا بالضبط سبب فشل "قبول السعر
    // النهائي" (السيرفر يرفض القبول قبل إغلاق المزاد وتحديد الفائز). نستدعيها
    // هنا بأمان (لا تفعل شيئاً لو ما في مزادات منتهية) في كل مرة تُفتح فيها
    // شاشة المزادات، كحل مؤقت لحين إضافة جدولة حقيقية على السيرفر.
    try {
      await _auctionService.closeExpiredAuctions();
    } catch (_) {
      // تجاهل أي فشل هنا (مثلاً صلاحيات) — لا نريده أن يمنع عرض القائمة
    }

    const statuses = ['pending', 'active', 'closed', 'ended', 'cancelled'];
    final results = await Future.wait(
      statuses.map(
        (s) => _auctionService
            .getAuctions(status: s)
            .catchError((_) => <Map<String, dynamic>>[]),
      ),
    );

    final seenIds = <int>{};
    final all = <Auction>[];
    for (final list in results) {
      for (final json in list) {
        final auction = Auction.fromJson(json);
        if (seenIds.add(auction.id)) all.add(auction);
      }
    }
    return all;
  }

  Future<void> _refresh() async {
    setState(_loadAuctions);
    await _auctionsFuture;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // زر التصنيف — يطبّق ترتيباً فعلياً على قائمة المزادات المعروضة (كان
  // غائباً تماماً بهذه الشاشة قبل التوحيد مع تصميم الشاشة الرئيسية)
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
                context.tr('filter_auctions'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(context.tr('ending_soon')),
                trailing:
                    _sortMode == 'ending_soon' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'ending_soon');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: AppHomeStyleHeader(
                title: context.tr('car_auctions'),
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                searchHint: context.tr('search_auctions'),
                onFilterTap: _showSortSheet,
              ),
            ),
            AuctionsFilterTabs(
              filters: _filters,
              selectedValue: _filter,
              onSelect: (value) => setState(() => _filter = value),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<Auction>>(
                  future: _auctionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonCarGrid(itemCount: 6);
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              'تعذر جلب المزادات\n'
                              '${ApiException.userMessage(snapshot.error)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }

                    final auctions = snapshot.data ?? const <Auction>[];

                    // نفس منطق المطابقة المرنة المستخدم بشاشة تفاصيل المزاد:
                    // الحالة النصية القادمة من السيرفر قد لا تكون بالضبط
                    // 'active'/'ended'، فنعتمد على contains + توقيتي البداية
                    // والنهاية بدل المطابقة الحرفية التي كانت تُفرغ تبويبي
                    // "قادمة" و"منتهية" دائماً.
                    final now = DateTime.now();
                    final statusFilteredAuctions =
                        auctions.where((a) {
                          final s = a.status.toLowerCase();
                          final notStartedYet = a.startTime.isAfter(now);
                          final timeIsUp = !a.endTime.isAfter(now);
                          final isTerminal =
                              s.contains('closed') ||
                              s.contains('ended') ||
                              s.contains('expired') ||
                              s.contains('accept') ||
                              s.contains('reject') ||
                              s.contains('complete') ||
                              s.contains('sold') ||
                              s.contains('cancel') ||
                              s.contains('withdraw');

                          if (_filter == 'upcoming') {
                            return notStartedYet && !isTerminal;
                          }
                          if (_filter == 'ended') {
                            return isTerminal || (timeIsUp && !notStartedYet);
                          }
                          // active
                          return !notStartedYet && !isTerminal && !timeIsUp;
                        }).toList();

                    final finalFilteredAuctions =
                        statusFilteredAuctions.where((auction) {
                          final fullName =
                              '${auction.car.make} ${auction.car.model}'
                                  .toLowerCase();
                          return fullName.contains(_searchQuery.toLowerCase());
                        }).toList();

                    double parsePrice(Auction a) =>
                        double.tryParse(a.currentPrice) ??
                        double.tryParse(a.startingPrice) ??
                        0;

                    switch (_sortMode) {
                      case 'price_asc':
                        finalFilteredAuctions.sort(
                          (a, b) => parsePrice(a).compareTo(parsePrice(b)),
                        );
                        break;
                      case 'price_desc':
                        finalFilteredAuctions.sort(
                          (a, b) => parsePrice(b).compareTo(parsePrice(a)),
                        );
                        break;
                      default:
                        finalFilteredAuctions.sort(
                          (a, b) => a.endTime.compareTo(b.endTime),
                        );
                    }

                    if (finalFilteredAuctions.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? context.tr('no_auctions_section')
                                  : context.tr('no_auction_results'),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: finalFilteredAuctions.length,
                      itemBuilder: (context, index) {
                        final auction = finalFilteredAuctions[index];
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AuctionDetailScreen(auction: auction),
                              ),
                            );
                            if (mounted) _refresh();
                          },
                          child: AuctionCard(auction: auction),
                        );
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
