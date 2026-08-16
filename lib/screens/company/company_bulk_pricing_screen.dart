import 'package:flutter/material.dart';
import 'package:mators_car/services/ads_service.dart';
import 'package:mators_car/ulits/colors.dart';

/// شاشة خاصة بالمعرض لتسعير الإعلانات "المسودة" (draft) الناتجة عن الرفع
/// الجماعي للسيارات (Bulk Upload) دون سعر، ثم تحديث أسعارها دفعة واحدة
/// عبر Endpoint: PUT /ads/bulk-publish
class CompanyBulkPricingScreen extends StatefulWidget {
  const CompanyBulkPricingScreen({super.key});

  @override
  State<CompanyBulkPricingScreen> createState() =>
      _CompanyBulkPricingScreenState();
}

class _CompanyBulkPricingScreenState extends State<CompanyBulkPricingScreen> {
  final AdsService _adsService = AdsService();
  late Future<List<Map<String, dynamic>>> _draftAdsFuture;
  final Map<int, TextEditingController> _priceControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _draftAdsFuture = _loadDrafts();
  }

  Future<List<Map<String, dynamic>>> _loadDrafts() async {
    final drafts = await _adsService.getMyAds(status: 'draft');
    for (final ad in drafts) {
      final id = ad['id'] as int;
      _priceControllers.putIfAbsent(id, () => TextEditingController());
    }
    return drafts;
  }

  Future<void> _refresh() async {
    setState(() {
      _draftAdsFuture = _loadDrafts();
    });
  }

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitPrices(List<Map<String, dynamic>> drafts) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final payload = <Map<String, dynamic>>[];

    for (final ad in drafts) {
      final id = ad['id'] as int;
      final text = _priceControllers[id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final price = double.tryParse(text);
      if (price == null || price <= 0) continue;
      payload.add({'ad_id': id, 'price': price});
    }

    if (payload.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('أدخل سعراً واحداً على الأقل قبل الحفظ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _adsService.bulkUpdatePrices(payload);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم تحديث أسعار الإعلانات بنجاح')),
      );
      await _refresh();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل تحديث الأسعار: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('تسعير الإعلانات المسودة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _draftAdsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر جلب الإعلانات المسودة\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد إعلانات مسودة بانتظار التسعير حالياً.\n'
                  'تظهر هنا السيارات التي تم رفعها بشكل جماعي دون تحديد سعر.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: drafts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ad = drafts[index];
                final id = ad['id'] as int;
                final car = ad['car'] is Map ? ad['car'] as Map : null;
                final carTitle =
                    car != null
                        ? '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim()
                        : 'سيارة #$id';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          carTitle.isEmpty ? 'سيارة #$id' : carTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _priceControllers[id],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'السعر',
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _draftAdsFuture,
            builder: (context, snapshot) {
              final drafts = snapshot.data ?? [];
              final enabled = drafts.isNotEmpty && !_isSubmitting;
              return ElevatedButton(
                onPressed: enabled ? () => _submitPrices(drafts) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C81),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text('حفظ الأسعار'),
              );
            },
          ),
        ),
      ),
    );
  }
}
