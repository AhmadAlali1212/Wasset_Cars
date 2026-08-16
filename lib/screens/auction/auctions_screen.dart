import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/models/auction_model.dart';
import 'package:mators_car/services/auction_service.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';
import 'auction_detail_screen.dart';

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
        (s) => _auctionService.getAuctions(status: s).catchError((_) => <Map<String, dynamic>>[]),
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
              const Text(
                'تصفية المزادات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('الأقرب للانتهاء'),
                trailing:
                    _sortMode == 'ending_soon' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortMode = 'ending_soon');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: AppHomeStyleHeader(
                title: 'مزادات السيارات',
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                searchHint: 'ابحث في المزادات المتاحة...',
                onFilterTap: _showSortSheet,
              ),
            ),
            Container(
              height: 60,
              color: Colors.white,
              child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filterItem = _filters[index];
                final isSelected = _filter == filterItem['value'];
                return GestureDetector(
                  onTap: () => setState(() => _filter = filterItem['value']!),
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF0F4C81)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF0F4C81)
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filterItem['title']!,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Auction>>(
                future: _auctionsFuture,
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
                            'تعذر جلب المزادات\n${snapshot.error}',
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
                                ? 'لا توجد مزادات متوفرة في هذا القسم حالياً'
                                : 'لا توجد نتائج تطابق بحثك في هذا القسم',
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
                        child: _buildAuctionCard(auction),
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

  Widget _buildAuctionCard(Auction auction) {
    final timeRemaining = auction.endTime.difference(DateTime.now());
    final daysRemaining = timeRemaining.inDays;
    final hoursRemaining = timeRemaining.inHours.remainder(24);
    final now = DateTime.now();
    final notStartedYet = auction.startTime.isAfter(now);
    final timeIsUp = !auction.endTime.isAfter(now);
    final s = auction.status.toLowerCase();
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
    final isActiveNow = !notStartedYet && !isTerminal && !timeIsUp;
    final isEndedNow = isTerminal || (timeIsUp && !notStartedYet);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                child:
                    auction.car.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: auction.car.images[0],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 800,
                          placeholder:
                              (context, url) => Container(
                                height: 180,
                                color: Colors.grey.shade200,
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/image/intro.jpg',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/image/intro.jpg',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActiveNow
                            ? '${daysRemaining}d ${hoursRemaining}h'
                            : isEndedNow
                            ? 'انتهى'
                            : 'قريباً',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${auction.car.make} ${auction.car.model} ${auction.car.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          auction.car.location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المزاد الحالي',
                          style: TextStyle(color: Colors.orange, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${auction.currentPrice} ل.س',
                          style: const TextStyle(
                            color: Color(0xFF0F4C81),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'السعر الابتدائي',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${auction.startingPrice} ل.س',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${auction.bids.length} مزايدة',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
