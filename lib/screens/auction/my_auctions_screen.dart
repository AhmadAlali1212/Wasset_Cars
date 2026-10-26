import 'package:flutter/material.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/services/controllers/auction_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'auction_detail_screen.dart';
import 'add_auction_screen.dart';
import 'package:mators_car/widgets/autction/my_auctions_widgets.dart';

// شاشة "مزاداتي" — أصبحت تستخدم GET /my-auctions المخصص مباشرة، بدل
// الحل الالتفافي القديم (جلب كل الحالات عبر GET /auctions العام ثم
// مطابقتها يدوياً مع GET /my-cars). هذا يحل من جذوره مشكلة "المزاد
// المنتهي يختفي" التي كانت تحدث حين تفشل المطابقة اليدوية بصمت.
class MyAuctionsScreen extends StatefulWidget {
  const MyAuctionsScreen({super.key});

  @override
  State<MyAuctionsScreen> createState() => _MyAuctionsScreenState();
}

class _MyAuctionsScreenState extends State<MyAuctionsScreen> {
  final AuctionService _auctionService = AuctionService();
  late Future<List<Auction>> _auctionsFuture;
  String _filter = 'all'; // all | active | pending | ended

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _auctionsFuture = _loadMyAuctions();
  }

  Future<List<Auction>> _loadMyAuctions() async {
    final raw = await _auctionService.getMyAuctions();
    return raw.map((json) => Auction.fromJson(json)).toList();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _auctionsFuture;
  }

  // نصنّف المزادات لـ 3 فئات لأن الحالة القادمة من السيرفر قد تكون
  // "قيد المراجعة" (لم تُعتمد بعد) بدل نشطة/منتهية مباشرة فقط.
  String _statusCategory(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending') ||
        s.contains('review') ||
        s.contains('draft') ||
        s.contains('awaiting')) {
      return 'pending';
    }
    if (s.contains('active') || s == 'upcoming') return 'active';
    return 'ended';
  }

  Future<void> _confirmDelete(Auction auction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('delete_auction')),
            content: Text(
              'هل أنت متأكد من حذف مزاد "${auction.car.make} ${auction.car.model}"؟ '
              'لا يمكن التراجع عن هذا الإجراء.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  context.tr('delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await _auctionService.deleteAuction(auction.id);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: context.tr('auction_deleted'));
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حذف المزاد',
        subtitle: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حذف المزاد',
        debugMessage: e,
      );
    }
  }

  Future<void> _goToEdit(Auction auction) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAuctionScreen(existingAuction: auction),
      ),
    );
    if (updated == true) _refresh();
  }

  Future<void> _goToCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAuctionScreen()),
    );
    if (created == true) {
      _refresh();
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        title: context.tr('auction_created'),
        subtitle: context.tr('auction_pending_review'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(context.tr('my_auctions')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreate,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          context.tr('new_auction'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MyAuctionFilterChip(
                    label: context.tr('all'),
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  MyAuctionFilterChip(
                    label: context.tr('active'),
                    selected: _filter == 'active',
                    onTap: () => setState(() => _filter = 'active'),
                  ),
                  const SizedBox(width: 8),
                  MyAuctionFilterChip(
                    label: context.tr('pending_review'),
                    selected: _filter == 'pending',
                    onTap: () => setState(() => _filter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  MyAuctionFilterChip(
                    label: context.tr('ended'),
                    selected: _filter == 'ended',
                    onTap: () => setState(() => _filter = 'ended'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Auction>>(
                future: _auctionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SkeletonList(itemCount: 5);
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            '${context.tr('my_auctions_load_failed')}\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  var auctions = snapshot.data ?? [];
                  if (_filter != 'all') {
                    auctions =
                        auctions
                            .where((a) => _statusCategory(a.status) == _filter)
                            .toList();
                  }

                  if (auctions.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 100),
                        Icon(
                          Icons.gavel_outlined,
                          size: 56,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 12),
                        Center(child: Text(context.tr('no_auctions_yet'))),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: auctions.length,
                    itemBuilder: (context, index) {
                      return MyAuctionOwnerCard(
                        auction: auctions[index],
                        statusCategory: _statusCategory(auctions[index].status),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AuctionDetailScreen(
                                    auction: auctions[index],
                                  ),
                            ),
                          );
                        },
                        onEdit: () => _goToEdit(auctions[index]),
                        onDelete: () => _confirmDelete(auctions[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
