import 'package:flutter/material.dart';
import 'package:mators_car/screens/adsCar/manage/add_rental_ad_screen.dart';
import 'package:mators_car/screens/adsCar/manage/add_sale_ad_screen.dart';
import 'package:mators_car/screens/adsCar/manage/rental_ads_list.dart';
import 'package:mators_car/screens/adsCar/manage/sale_ads_list.dart';

/// شاشة موحّدة لإدارة إعلانات البيع والتأجير معاً، بتبويبين منفصلين.
/// تُستخدم من قِبل حساب الفرد وحساب المعرض على حد سواء لأن آلية
/// إدارة الإعلانات (إنشاء / تعديل / نشر / حذف) متطابقة بينهما عبر الـ API.
class ManageAdsScreen extends StatefulWidget {
  final String title;
  final List<Widget>? actions;

  const ManageAdsScreen({super.key, this.title = 'إدارة الإعلانات', this.actions});

  @override
  State<ManageAdsScreen> createState() => _ManageAdsScreenState();
}

class _ManageAdsScreenState extends State<ManageAdsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // مفاتيح فريدة تتغيّر عند الحاجة لإجبار قوائم الإعلانات على إعادة الجلب
  int _saleListVersion = 0;
  int _rentalListVersion = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshActiveTab() async {
    // إعادة إنشاء التبويبين معاً (أبسط وأكثر أماناً بعد إضافة/تعديل إعلان)
    setState(() {
      _saleListVersion++;
      _rentalListVersion++;
    });
  }

  Future<void> _openAddMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'نوع الإعلان',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.sell_outlined),
                  title: const Text('إعلان بيع'),
                  onTap: () => Navigator.pop(context, 'sale'),
                ),
                ListTile(
                  leading: const Icon(Icons.car_rental_outlined),
                  title: const Text('إعلان تأجير'),
                  onTap: () => Navigator.pop(context, 'rental'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    bool? created;
    if (choice == 'sale') {
      created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AddSaleAdScreen()),
      );
    } else {
      created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AddRentalAdScreen()),
      );
    }

    if (created == true) {
      await _refreshActiveTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: widget.actions,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F4C81),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF0F4C81),
          tabs: const [
            Tab(text: 'إعلانات البيع'),
            Tab(text: 'إعلانات التأجير'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SaleAdsList(key: ValueKey('sale_ads_$_saleListVersion')),
          RentalAdsList(key: ValueKey('rental_ads_$_rentalListVersion')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMenu,
        backgroundColor: const Color(0xFF0F4C81),
        icon: const Icon(Icons.add),
        label: const Text('إعلان جديد'),
      ),
    );
  }
}
