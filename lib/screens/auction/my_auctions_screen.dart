import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/models/auction_model.dart';
import 'package:mators_car/services/auction_service.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constans.dart';
import 'auction_detail_screen.dart';
import 'add_auction_screen.dart';

// شاشة "مزاداتي": الـ API لا يوفّر endpoint مخصص لمزادات المستخدم فقط
// (فقط GET /auctions العام)، لذلك نجلب كل المزادات ونصفّيها محلياً حسب
// السيارات التي يملكها المستخدم.
class MyAuctionsScreen extends StatefulWidget {
  const MyAuctionsScreen({super.key});

  @override
  State<MyAuctionsScreen> createState() => _MyAuctionsScreenState();
}

class _MyAuctionsScreenState extends State<MyAuctionsScreen> {
  final AuctionService _auctionService = AuctionService();
  final CompanyService _carService = CompanyService();
  late Future<List<Auction>> _auctionsFuture;
  String _filter = 'all'; // all | active | ended

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _auctionsFuture = _loadMyAuctions();
  }

  Future<List<Auction>> _loadMyAuctions() async {
    // القيم الصحيحة الوحيدة الموثّقة لفلتر status بـ GET /auctions هي:
    // pending, active, closed, cancelled (موثّقة صراحة بـ Postman). أضفنا
    // 'ended' أيضاً احتياطاً لأنك استخدمتها فعلياً لاختبار الحالة، حتى لو
    // لم تكن موثّقة رسمياً كقيمة فلترة صالحة.
    const statuses = ['pending', 'active', 'closed', 'ended', 'cancelled'];

    // GET /auctions يعرض بيانات السيارة المتداخلة (car) بشكل قد يكون
    // غير مكتمل لمزادات ليست active (خصوصاً closed)، فالاعتماد على
    // auction.car.userId لتحديد الملكية كان يفشل بصمت في هذه الحالة.
    // البديل الموثوق: مقارنة auction.carId (حقل مباشر لا يعتمد على
    // اكتمال الكائن المتداخل) بقائمة معرّفات سياراتي الحقيقية عبر
    // GET /my-cars.
    final results = await Future.wait([
      ...statuses.map(
        (s) => _auctionService.getAuctions(status: s).catchError((_) => <Map<String, dynamic>>[]),
      ),
      _carService.getMyCars().catchError((_) => <Map<String, dynamic>>[]),
    ]);

    final myCarsRaw = results.last;
    final myCarIds =
        myCarsRaw.map((c) => int.tryParse('${c['id']}')).whereType<int>().toSet();

    final seenIds = <int>{};
    final all = <Auction>[];
    for (final list in results.sublist(0, statuses.length)) {
      for (final json in list) {
        final auction = Auction.fromJson(json);
        if (seenIds.add(auction.id)) all.add(auction);
      }
    }

    // نطابق أولاً عبر قائمة سياراتي (الطريقة الموثوقة)، ونسمح احتياطياً
    // بمطابقة car.userId إن وصلت (في حال فشل جلب /my-cars لأي سبب) حتى
    // لا نفقد كل النتائج دفعة واحدة.
    if (myCarIds.isNotEmpty) {
      return all.where((a) => myCarIds.contains(a.carId)).toList();
    }
    final user = await AuthStorage.getUser();
    final myId = int.tryParse('${user?['id']}') ?? -1;
    return all.where((a) => a.car.userId == myId).toList();
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
            title: const Text('حذف المزاد'),
            content: Text(
              'هل أنت متأكد من حذف مزاد "${auction.car.make} ${auction.car.model}"؟ '
              'لا يمكن التراجع عن هذا الإجراء.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _auctionService.deleteAuction(auction.id);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم حذف المزاد بنجاح')),
      );
      _refresh();
    } on ApiException catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('تعذر حذف المزاد: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء المزاد بنجاح، وهو الآن قيد المراجعة ⏳'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('مزاداتي', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreate,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('مزاد جديد', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('الكل', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('نشطة', 'active'),
                  const SizedBox(width: 8),
                  _filterChip('قيد المراجعة', 'pending'),
                  const SizedBox(width: 8),
                  _filterChip('منتهية', 'ended'),
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            'تعذر جلب مزاداتك\n${snapshot.error}',
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
                            .where(
                              (a) => _statusCategory(a.status) == _filter,
                            )
                            .toList();
                  }

                  if (auctions.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Icon(
                          Icons.gavel_outlined,
                          size: 56,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 12),
                        Center(child: Text('لا توجد مزادات بعد')),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: auctions.length,
                    itemBuilder: (context, index) {
                      return _AuctionOwnerCard(
                        auction: auctions[index],
                        statusCategory: _statusCategory(
                          auctions[index].status,
                        ),
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

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AuctionOwnerCard extends StatelessWidget {
  final Auction auction;
  final String statusCategory; // active | pending | ended
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AuctionOwnerCard({
    required this.auction,
    required this.statusCategory,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _badgeColor() {
    final s = auction.status.toLowerCase();
    switch (statusCategory) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        if (s.contains('reject') || s.contains('cancel') || s.contains('withdraw')) {
          return Colors.red;
        }
        if (s.contains('complete') || s.contains('sold') || s.contains('done')) {
          return Colors.blue;
        }
        if (s.contains('accept')) return AppColors.primary;
        return Colors.black54;
    }
  }

  String _badgeLabel() {
    final s = auction.status.toLowerCase();
    switch (statusCategory) {
      case 'active':
        return 'نشط';
      case 'pending':
        return 'قيد المراجعة';
      default:
        if (s.contains('reject')) return 'مرفوض';
        if (s.contains('cancel')) return 'ملغى';
        if (s.contains('withdraw')) return 'تراجع الفائز';
        if (s.contains('complete') || s.contains('sold') || s.contains('done')) {
          return 'مكتمل ✅';
        }
        if (s.contains('accept')) return 'بانتظار إتمام البيع';
        return 'منتهٍ - بانتظار قرارك';
    }
  }

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
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.grey,
                          ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _badgeLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _badgeColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'أعلى مزايدة: ${auction.currentPrice} ل.س',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عدد المزايدات: ${auction.bids.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (statusCategory == 'ended')
                      // بعد انتهاء المزاد لا معنى لتعديله أو حذفه؛ التوجيه
                      // لصفحة التفاصيل حيث تظهر أزرار القبول/الرفض/التأكيد
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.arrow_forward_ios, size: 12),
                          label: const Text('عرض التفاصيل واتخاذ القرار'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('تعديل'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'حذف',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
