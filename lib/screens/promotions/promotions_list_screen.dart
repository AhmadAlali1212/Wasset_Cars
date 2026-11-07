import 'package:flutter/material.dart';
import 'package:mators_car/data/models/promotion_model.dart';
import 'package:mators_car/services/controllers/promotion_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/services/local_promotions_cache.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'add_promotion_screen.dart';
import 'promotion_detail_screen.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PromotionService _promotionService = PromotionService();
  late Future<List<Promotion>> _promotionsFuture;
  String _filter = 'all';
  String _searchQuery = '';

  final List<Map<String, String>> _filters = const [
    {'title': 'الكل', 'value': 'all'},
    {'title': 'نشط', 'value': 'approved'},
    {'title': 'بانتظار المراجعة', 'value': 'pending'},
    {'title': 'منتهي', 'value': 'expired'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _promotionsFuture = _loadPromotions();
  }

  Future<List<Promotion>> _loadPromotions() async {
    final serverList = await _promotionService.getPromotions();
    // ننظّف الكاش من أي عرض صار موجوداً فعلياً برد السيرفر (اعتماده تأكد)
    await LocalPromotionsCache.reconcile(serverList);

    final cached = await LocalPromotionsCache.getAll();
    final serverIds = serverList.map((p) => p['id']).toSet();
    final merged = [
      ...serverList,
      ...cached.where((p) => !serverIds.contains(p['id'])),
    ];
    return merged.map((json) => Promotion.fromJson(json)).toList();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _promotionsFuture;
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
        title: const Text(
          'العروض الترويجية',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPromotionScreen(),
                ),
              );
              if (created == true) {
                _refresh();
                if (!context.mounted) return;
                AppSnackbar.showSuccess(
                  context,
                  title: 'تم إنشاء العرض الترويجي بنجاح',
                  subtitle: 'وهو الآن قيد المراجعة',
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  textAlign: TextAlign.right,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن عرض...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final f = _filters[index];
                  final isSelected = _filter == f['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f['value']!),
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        f['title']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Promotion>>(
                future: _promotionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Text(
                            'تعذر جلب العروض\n'
                            '${ApiException.userMessage(snapshot.error)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  var promos = snapshot.data ?? const <Promotion>[];

                  if (_filter == 'approved') {
                    promos =
                        promos
                            .where(
                              (p) => p.status == 'approved' && !p.isExpired,
                            )
                            .toList();
                  } else if (_filter == 'pending') {
                    promos =
                        promos.where((p) => p.status == 'pending').toList();
                  } else if (_filter == 'expired') {
                    promos = promos.where((p) => p.isExpired).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    promos =
                        promos
                            .where(
                              (p) => p.title.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();
                  }

                  if (promos.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'لا توجد عروض ترويجية لعرضها',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: promos.length,
                    itemBuilder: (context, index) {
                      final promo = promos[index];
                      return GestureDetector(
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PromotionDetailScreen(promotion: promo),
                            ),
                          );
                          if (changed == true) _refresh();
                        },
                        child: _buildPromoCard(promo),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(Promotion promo) {
    final statusLabel =
        promo.isExpired
            ? 'منتهي'
            : promo.status == 'pending'
            ? 'قيد المراجعة'
            : promo.status == 'rejected'
            ? 'مرفوض'
            : 'نشط';
    final statusColor =
        promo.isExpired
            ? Colors.grey
            : promo.status == 'pending'
            ? Colors.orange
            : promo.status == 'rejected'
            ? Colors.red
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.favorite_border,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            promo.title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            promo.type == 'discount'
                ? 'خصم ${promo.value.toStringAsFixed(0)}%'
                : promo.value.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                promo.isExpired
                    ? 'انتهى العرض'
                    : 'ينتهي خلال ${promo.daysRemaining} يوم',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.quantity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'الكمية المتاحة',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                PromotionDetailScreen(promotion: promo),
                      ),
                    );
                    if (changed == true) _refresh();
                  },
                  child: const Text(
                    'تعديل',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
