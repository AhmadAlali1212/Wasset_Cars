import 'package:flutter/material.dart';
import 'package:mators_car/screens/individual/individual_add_car_screen.dart';
import 'package:mators_car/screens/individual/individual_inventory_screen.dart';
import 'package:mators_car/screens/individual/individual_wallet_screen.dart';
import 'package:mators_car/services/company_service.dart';

class IndividualDashboardScreen extends StatefulWidget {
  const IndividualDashboardScreen({super.key});

  @override
  State<IndividualDashboardScreen> createState() =>
      _IndividualDashboardScreenState();
}

class _IndividualDashboardScreenState extends State<IndividualDashboardScreen> {
  final CompanyService _carService = CompanyService();

  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<Map<String, dynamic>> _loadSummary() async {
    final cars = await _carService.getCompanyCars();
    final wallet = await _carService.getWallet();
    return {'cars': cars, 'wallet': wallet};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('لوحة المستخدم'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر جلب بيانات الحساب\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final cars = List<Map<String, dynamic>>.from(
            snapshot.data?['cars'] ?? [],
          );
          final wallet = Map<String, dynamic>.from(
            snapshot.data?['wallet'] ?? {},
          );
          final balance = wallet['balance'] ?? wallet['current_balance'] ?? 0;
          final currency = wallet['currency'] ?? 'ل.س';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _summaryFuture = _loadSummary();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حساب الفرد',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'أهلاً بك في لوحة التحكم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'الرصيد: $balance $currency',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildActionTile(
                    title: 'سياراتي',
                    subtitle: '${cars.length} سيارة',
                    icon: Icons.directions_car_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualInventoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    title: 'المحفظة',
                    subtitle: 'اطلع على الرصيد والحركات',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualWalletScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    title: 'أضف سيارة جديدة',
                    subtitle: 'أضف السيارة وسيتم مراجعتها',
                    icon: Icons.add_circle_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualAddCarScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'أحدث السيارات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (cars.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'لم تتم إضافة سيارات بعد. استخدم زر "أضف سيارة جديدة" لبدء العملية.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    Column(
                      children:
                          cars.take(3).map((car) {
                            final title =
                                '${car['make'] ?? ''} ${car['model'] ?? ''}';
                            final year = car['year']?.toString() ?? '';
                            final status = car['status'] ?? 'غير معروف';
                            final imageUrl =
                                car['images'] is List &&
                                        (car['images'] as List).isNotEmpty
                                    ? (car['images'] as List).first.toString()
                                    : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading:
                                    imageUrl != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Container(
                                                  width: 70,
                                                  height: 70,
                                                  color: const Color(
                                                    0xFFF0F0F0,
                                                  ),
                                                  child: const Icon(
                                                    Icons.directions_car,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        )
                                        : Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0F0F0),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.directions_car,
                                            color: Colors.grey,
                                          ),
                                        ),
                                title: Text(
                                  title.trim().isEmpty
                                      ? 'سيارة غير محددة'
                                      : title,
                                ),
                                subtitle: Text('$year • الحالة: $status'),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const IndividualInventoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0F4C81).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF0F4C81)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
