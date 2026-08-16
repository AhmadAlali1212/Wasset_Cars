import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/screens/individual/individual_add_car_screen.dart';
import 'package:mators_car/screens/individual/individual_ads_screen.dart';
import 'package:mators_car/screens/individual/individual_inventory_screen.dart';
import 'package:mators_car/screens/individual/individual_profile_screen.dart';
import 'package:mators_car/screens/individual/individual_wallet_screen.dart';
import 'package:mators_car/screens/auction/my_auctions_screen.dart';
import 'package:mators_car/screens/auction/my_bids_screen.dart';
import 'package:mators_car/screens/adsCar/rental/my_rental_bookings_screen.dart';
import 'package:mators_car/screens/company/following_companies_screen.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/ulits/constans.dart';

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
    final myCars = await _carService.getMyCars();
    final allCars = await _carService.getAllCars();
    final wallet = await _carService.getWallet();
    return {'myCars': myCars, 'allCars': allCars, 'wallet': wallet};
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'الحساب',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IndividualProfileScreen(),
                ),
              );
            },
          ),
        ],
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

          final myCars = List<Map<String, dynamic>>.from(
            snapshot.data?['myCars'] ?? [],
          );
          final allCars = List<Map<String, dynamic>>.from(
            snapshot.data?['allCars'] ?? [],
          );
          final wallet = Map<String, dynamic>.from(
            snapshot.data?['wallet'] ?? {},
          );
          final walletData = wallet['wallet'];
          final balanceRaw =
              (walletData is Map ? walletData['available_balance'] : null) ??
              wallet['balance'] ??
              wallet['current_balance'] ??
              0;
          final balance = balanceRaw;
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
                    subtitle: '${myCars.length} سيارة',
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
                    title: 'إعلاناتي',
                    subtitle: 'اعرض إعلاناتك المنشورة أو قيد الانتظار',
                    icon: Icons.campaign_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualAdsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    title: 'مزاداتي',
                    subtitle: 'أنشئ مزاداً على إحدى سياراتك أو عدّله',
                    icon: Icons.gavel_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAuctionsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    title: 'مزايداتي',
                    subtitle: 'المزادات التي زايدت عليها ونتيجتها',
                    icon: Icons.emoji_events_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyBidsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    title: 'حجوزات التأجير',
                    subtitle: 'الحجوزات التي قمت بها على سيارات مؤجَّرة',
                    icon: Icons.event_available_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyRentalBookingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionTile(
                    title: 'الشركات التي أتابعها',
                    subtitle: 'تابع أحدث سيارات وعروض معارضك المفضلة',
                    icon: Icons.storefront_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FollowingCompaniesScreen(),
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
                  _buildActionTile(
                    title: 'الحساب الشخصي',
                    subtitle: 'تعديل بيانات الحساب وتسجيل الخروج',
                    icon: Icons.person_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndividualProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'كل السيارات المتاحة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (allCars.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'لا توجد سيارات منشورة حالياً على التطبيق.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    Column(
                      children:
                          allCars.take(3).map((car) {
                            final title =
                                '${car['make'] ?? ''} ${car['model'] ?? ''}';
                            final year = car['year']?.toString() ?? '';
                            final status = car['approval_status'] ?? car['status'] ?? 'غير معروف';
                            final imageUrl = AppConstants.resolveImageUrl(
                              car['images'] is List &&
                                      (car['images'] as List).isNotEmpty
                                  ? (car['images'] as List).first.toString()
                                  : null,
                            );

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
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 140,
                                            placeholder:
                                                (_, __) => Container(
                                                  width: 70,
                                                  height: 70,
                                                  color: const Color(0xFFF0F0F0),
                                                ),
                                            errorWidget:
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
                                      builder:
                                          (_) =>
                                              const IndividualInventoryScreen(),
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
