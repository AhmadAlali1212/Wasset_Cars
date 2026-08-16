import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/screens/company/company_dashboard_screen.dart';
import 'package:mators_car/screens/individual/individual_dashboard_screen.dart';
import 'package:mators_car/screens/auction/auctions_screen.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAds_screen.dart'; // صفحة التأجير المحدثة
import 'package:mators_car/screens/adsCar/sellCars/home_ads_screen.dart'; // سيارات التطبيق المعروضة للمستخدمين
import 'package:mators_car/screens/promotions/promoted_cars_screen.dart';
import 'package:mators_car/services/auth_serivces.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // التبويب الأول أصبح يعرض سيارات التطبيق الفعلية المعروضة للمستخدمين
  // (بدلاً من لوحة المعرض)، وتبويب الحساب أصبح يعرض لوحة المعرض/التحكم
  // مباشرة، ومن داخلها يمكن الدخول إلى الحساب الشخصي.
  // زر "الإضافة" الأوسط (index 2) أصبح يعرض شاشة العروض الترويجية بدل
  // شاشة إضافة سيارة مباشرة — إضافة السيارة ما زالت متاحة عبر لوحة
  // التحكم/المعرض (تبويب index 4) كما كانت أصلاً.
  List<Widget> _buildScreens(bool isCompany) {
    return [
      const HomeScreen(),
      RentalAdsScreen(),
      const PromotedCarsScreen(),
      const AuctionsScreen(),
      if (isCompany)
        const CompanyDashboardScreen()
      else
        const IndividualDashboardScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _animationController.reset();
        _currentIndex = index;
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final rawAccountType = authService.currentUser?['account_type'];
    final accountTypeStr =
        rawAccountType is Map
            ? (rawAccountType['name'] ?? rawAccountType['type'] ?? '')
                .toString()
            : (rawAccountType ?? '').toString();
    final isCompanyAccount =
        accountTypeStr.toLowerCase() == 'company' ||
        authService.currentUser?['account_type_id'] == 2;
    final screens = _buildScreens(isCompanyAccount);
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);
    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = safeIndex;
          });
        }
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Stack(
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: screens[safeIndex],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildModernNavBar(isCompanyAccount),
      ),
    );
  }

  Widget _buildModernNavBar(bool isCompany) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, 'الرئيسية'),
              _buildNavItem(
                1,
                Icons.car_rental_outlined,
                'التأجير',
              ), // الأيقونة المحدثة للتأجير
              _buildNavItem(2, Icons.local_offer_outlined, 'العروض'),
              _buildNavItem(3, Icons.gavel_rounded, 'المزادات'),
              _buildNavItem(
                4,
                Icons.storefront_outlined,
                isCompany ? 'لوحة المعرض' : 'لوحة التحكم',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = const Color(0xFF0F4C81);
    final inactiveColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
