import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/screens/company/company_add_car_wizard_screen.dart';
import 'package:mators_car/screens/company/company_dashboard_screen.dart';
import 'package:mators_car/screens/individual/individual_add_car_screen.dart';
import 'package:mators_car/screens/individual/individual_dashboard_screen.dart';
import 'package:mators_car/screens/profile_screen.dart';
import 'package:mators_car/ulits/mock_data.dart';
import 'package:mators_car/screens/auction/auctions_screen.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAds_screen.dart'; // صفحة التأجير المحدثة
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

  // استبدال المفضلة بالتأجير في التبويب الثاني (الدليل الرقمي 1)
  List<Widget> _buildScreens(bool isCompany) {
    return [
      if (isCompany)
        const CompanyDashboardScreen()
      else
        const IndividualDashboardScreen(),
      RentalAdsScreen(),
      if (isCompany)
        const CompanyAddCarWizardScreen()
      else
        const IndividualAddCarScreen(),
      AuctionsScreen(auctions: MockData.auctions),
      const ProfileScreen(),
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
    final isCompanyAccount =
        authService.currentUser?['account_type'] == 'company' ||
        authService.currentUser?['account_type_id'] == 2;
    final screens = _buildScreens(isCompanyAccount);

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
                child: screens[_currentIndex],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildModernNavBar(isCompanyAccount),
      ),
    );
  }

  Widget _buildModernNavBar(bool isCompany) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            0,
            Icons.home_filled,
            isCompany ? 'المعرض' : 'لوحة التحكم',
          ),
          _buildNavItem(
            1,
            Icons.car_rental_outlined,
            'التأجير',
          ), // الأيقونة المحدثة للتأجير
          _buildCenterPlusButton(),
          _buildNavItem(3, Icons.gavel_rounded, 'المزادات'),
          _buildNavItem(4, Icons.person_outline, 'الحساب'),
        ],
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

  Widget _buildCenterPlusButton() {
    return GestureDetector(
      onTap: () {
        if (_currentIndex == 2) {
          setState(() {
            _currentIndex = 2;
          });
        }
      },
      child: Container(
        width: 54,
        height: 54,
        transform: Matrix4.translationValues(0, -10, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F4C81),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F4C81).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
