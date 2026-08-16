import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/models/auction_model.dart';
import 'package:mators_car/services/auction_service.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constans.dart';
import 'auction_detail_screen.dart';

// شاشة "مزايداتي": المزادات التي زايدت عليها (بصفتك مشترياً/مزايداً لا
// مالكاً). لم تكن موجودة إطلاقاً سابقاً، رغم أن GET /auctions يعرض active
// فقط افتراضياً — فبمجرد أن ينتهي المزاد لم يكن هناك أي وسيلة للفائز أو أي
// مزايد آخر لإيجاده مجدداً ومعرفة نتيجته (فاز أم لا).
class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final AuctionService _auctionService = AuctionService();
  late Future<List<Auction>> _auctionsFuture;
  int? _myId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _auctionsFuture = _loadMyBidAuctions();
  }

  Future<List<Auction>> _loadMyBidAuctions() async {
    final user = await AuthStorage.getUser();
    final myId = int.tryParse('${user?['id']}') ?? -1;
    _myId = myId;

    // نجلب كل الحالات الممكنة (نفس منطق "مزاداتي") لأن GET /auctions
    // يعرض active فقط افتراضياً. القيم الموثّقة لفلتر status هي: pending,
    // active, closed, cancelled + 'ended' احتياطاً.
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
    // نعرض فقط المزادات التي وضعت عليها مزايدة واحدة على الأقل
    return all
        .where((a) => a.bids.any((b) => b.userId == myId))
        .toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
  }

  Future<void> _refresh() async {
    setState(_load);
    await _auctionsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('مزايداتي', style: TextStyle(color: Colors.black)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Auction>>(
          future: _auctionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'تعذر جلب مزايداتك\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final auctions = snapshot.data ?? [];
            if (auctions.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.gavel_outlined, size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Center(child: Text('لم تشارك بأي مزاد بعد')),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: auctions.length,
              itemBuilder: (context, index) {
                final auction = auctions[index];
                final isWinner = _myId != null && auction.winnerId == _myId;
                final hasEnded = !auction.endTime.isAfter(DateTime.now()) ||
                    auction.status.toLowerCase().contains('closed') ||
                    auction.status.toLowerCase().contains('ended');

                return _MyBidCard(
                  auction: auction,
                  isWinner: isWinner,
                  hasEnded: hasEnded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuctionDetailScreen(auction: auction),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MyBidCard extends StatelessWidget {
  final Auction auction;
  final bool isWinner;
  final bool hasEnded;
  final VoidCallback onTap;

  const _MyBidCard({
    required this.auction,
    required this.isWinner,
    required this.hasEnded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConstants.resolveImageUrl(
      auction.car.images.isNotEmpty ? auction.car.images.first : null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child:
                    imageUrl != null
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          memCacheWidth: 168,
                          placeholder:
                              (_, __) => Container(
                                width: 84,
                                height: 84,
                                color: const Color(0xFFF0F0F0),
                              ),
                          errorWidget:
                              (_, __, ___) => Container(
                                width: 84,
                                height: 84,
                                color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.directions_car, color: Colors.grey),
                              ),
                        )
                        : Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.directions_car, color: Colors.grey),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${auction.car.make} ${auction.car.model} ${auction.car.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // الشارة الأهم بهذه الشاشة: تُظهر للفائز فوزه بوضوح
                        if (isWinner && hasEnded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🏆 أنت الفائز',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (!hasEnded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'المزاد جارٍ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'لم تفز بهذا المزاد',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'السعر الحالي: ${auction.currentPrice} ل.س',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عدد المزايدات: ${auction.bids.length}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
