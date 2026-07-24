import 'package:flutter/material.dart';
import 'package:mators_car/services/company_service.dart';

class CompanyInventoryScreen extends StatefulWidget {
  const CompanyInventoryScreen({super.key});

  @override
  State<CompanyInventoryScreen> createState() => _CompanyInventoryScreenState();
}

class _CompanyInventoryScreenState extends State<CompanyInventoryScreen> {
  final CompanyService _companyService = CompanyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('سيارات المعرض'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _companyService.getCompanyCars(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر جلب سيارات المعرض\n${snapshot.error}',
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
                  Icon(Icons.storefront_outlined, size: 70, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد سيارات في المعرض بعد',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'استخدم زر الإضافة لإدخال أول سيارة لك',
                    style: TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cars.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final car = cars[index];
              final title = car['make'] ?? car['name'] ?? 'سيارة غير معروفة';
              final model = car['model'] ?? 'موديل غير محدد';
              final status = car['status'] ?? 'غير معروف';
              final price =
                  car['price'] != null
                      ? '${car['price']} ل.س'
                      : 'السعر غير متوفر';
              final imageUrl = car['image'] ?? car['images']?.first ?? null;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child:
                        imageUrl != null
                            ? Image.network(
                              imageUrl.toString(),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 70,
                                    height: 70,
                                    color: const Color(0xFFF0F0F0),
                                    child: const Icon(
                                      Icons.car_repair,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                            : Container(
                              width: 70,
                              height: 70,
                              color: const Color(0xFFF0F0F0),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                  title: Text(
                    '$title • $model',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(price),
                      const SizedBox(height: 4),
                      Text(
                        'الحالة: $status',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
