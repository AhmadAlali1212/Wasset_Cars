import 'package:flutter/material.dart';
import 'package:mators_car/services/company_service.dart';

class IndividualInventoryScreen extends StatefulWidget {
  const IndividualInventoryScreen({super.key});

  @override
  State<IndividualInventoryScreen> createState() =>
      _IndividualInventoryScreenState();
}

class _IndividualInventoryScreenState extends State<IndividualInventoryScreen> {
  final CompanyService _carService = CompanyService();
  late Future<List<Map<String, dynamic>>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _carsFuture = _carService.getCompanyCars();
  }

  Future<void> _refreshCars() async {
    setState(() {
      _carsFuture = _carService.getCompanyCars();
    });
  }

  Future<void> _requestInspection(int carId) async {
    try {
      await _carService.requestInspection(carId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم طلب الفحص الفني بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل طلب الفحص: ${e.toString()}')));
    }
  }

  Future<void> _deleteCar(int carId) async {
    try {
      await _carService.deleteCar(carId);
      await _refreshCars();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف السيارة بنجاح')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف السيارة: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('سياراتي'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر جلب سياراتك\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final cars = snapshot.data ?? [];
          if (cars.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.directions_car_filled_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'لم يتم إضافة سيارات بعد',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'استخدم لوحة التحكم لإضافة أول سيارة لك',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshCars,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cars.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final car = cars[index];
                final title =
                    '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim();
                final year = car['year']?.toString() ?? '-';
                final status = car['status'] ?? 'غير معروف';
                final imageUrl =
                    car['images'] is List && (car['images'] as List).isNotEmpty
                        ? (car['images'] as List).first.toString()
                        : null;
                final carId = car['id'] as int? ?? car['car_id'] as int? ?? 0;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            imageUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.directions_car,
                                          size: 40,
                                        ),
                                  ),
                                )
                                : const CircleAvatar(
                                  radius: 30,
                                  child: Icon(Icons.directions_car, size: 30),
                                ),
                        title: Text(title.isEmpty ? 'سيارة غير محددة' : title),
                        subtitle: Text('سنة $year • الحالة: $status'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'inspect') {
                              _requestInspection(carId);
                            } else if (value == 'delete') {
                              _deleteCar(carId);
                            }
                          },
                          itemBuilder:
                              (_) => [
                                const PopupMenuItem(
                                  value: 'inspect',
                                  child: Text('طلب فحص فني'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف السيارة'),
                                ),
                              ],
                        ),
                      ),
                      if ((car['description'] as String?)?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            car['description'],
                            style: const TextStyle(color: Colors.black87),
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
    );
  }
}
