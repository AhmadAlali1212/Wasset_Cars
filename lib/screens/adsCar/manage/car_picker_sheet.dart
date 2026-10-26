import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constans.dart';

/// ورقة سفلية مشتركة لاختيار سيارة من سيارات المستخدم (فردي أو معرض)
/// قبل إنشاء إعلان بيع أو تأجير جديد.
/// تُستخدم من قِبل: add_sale_ad_screen و add_rental_ad_screen لكلا الحسابين.
class CarPickerSheet extends StatefulWidget {
  const CarPickerSheet({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CarPickerSheet(),
    );
  }

  @override
  State<CarPickerSheet> createState() => _CarPickerSheetState();
}

class _CarPickerSheetState extends State<CarPickerSheet> {
  final CompanyService _carService = CompanyService();
  late Future<List<Map<String, dynamic>>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _carsFuture = _carService.getMyCars();
  }

  String? _primaryImage(dynamic imagesData) {
    String? raw;
    if (imagesData is List && imagesData.isNotEmpty) {
      final first = imagesData.first;
      if (first is String) raw = first;
      if (first is Map && first['url'] != null) raw = first['url'].toString();
      if (first is Map && first['image_path'] != null) {
        raw = first['image_path'].toString();
      }
    } else if (imagesData is String && imagesData.isNotEmpty) {
      raw = imagesData;
    }
    return AppConstants.resolveImageUrl(raw);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'اختر السيارة',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _carsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'تعذر جلب السيارات\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final cars = snapshot.data ?? [];
                    if (cars.isEmpty) {
                      return const Center(
                        child: Text('لا توجد سيارات مضافة بعد لاختيارها'),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: cars.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final car = cars[index];
                        final make = car['make'] ?? '';
                        final model = car['model'] ?? '';
                        final year = car['year']?.toString() ?? '-';
                        final status = (car['approval_status'] ?? car['status'])?.toString() ?? '';
                        final imageUrl = _primaryImage(
                          car['images'] ?? car['image'],
                        );

                        return Card(
                          elevation: 0,
                          color: AppColors.surfaceLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  imageUrl != null
                                      ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 112,
                                        placeholder:
                                            (_, __) => Container(
                                              width: 56,
                                              height: 56,
                                              color: const Color(0xFFF0F0F0),
                                            ),
                                        errorWidget:
                                            (_, __, ___) => Container(
                                              width: 56,
                                              height: 56,
                                              color: const Color(0xFFF0F0F0),
                                              child: const Icon(
                                                Icons.directions_car,
                                              ),
                                            ),
                                      )
                                      : Container(
                                        width: 56,
                                        height: 56,
                                        color: const Color(0xFFF0F0F0),
                                        child: const Icon(Icons.directions_car),
                                      ),
                            ),
                            title: Text(
                              '$make $model'.trim().isEmpty
                                  ? 'سيارة غير محددة'
                                  : '$make $model',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('سنة $year • الحالة: $status'),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => Navigator.pop(context, car),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
