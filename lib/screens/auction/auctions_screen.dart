import 'package:flutter/material.dart';
import 'package:mators_car/models/auction_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'auction_detail_screen.dart';

class AuctionsScreen extends StatefulWidget {
  final List<Auction> auctions;

  const AuctionsScreen({super.key, required this.auctions});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  // الفلاتر العلوية
  String _filter = 'active';
  final List<Map<String, String>> _filters = [
    {'title': 'نشطة', 'value': 'active'},
    {'title': 'قادمة', 'value': 'upcoming'},
    {'title': 'منتهية', 'value': 'ended'},
  ];

  // متغيرات حالة البحث المتفاعل
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    // 1. التصفية الأولى: بناءً على حالة الفلتر المختار (نشطة / قادمة / منتهية)
    final statusFilteredAuctions =
        widget.auctions.where((a) {
          if (_filter == 'active') return a.status == 'active';
          if (_filter == 'upcoming') return a.startTime.isAfter(DateTime.now());
          if (_filter == 'ended') return a.status == 'ended';
          return true;
        }).toList();

    // 2. التصفية الثانية: البحث المتفاعل داخل الفلتر الحالي (البحث في الماركة أو الموديل)
    final finalFilteredAuctions =
        statusFilteredAuctions.where((auction) {
          final fullName =
              '${auction.car.make} ${auction.car.model}'.toLowerCase();
          return fullName.contains(_searchQuery.toLowerCase());
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // تفعيل خانة البحث مكان العنوان تماماً مثل صفحة التأجير
        title:
            _isSearching
                ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    autofocus: true,
                    textAlign: TextAlign.right,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'ابحث في المزادات المتاحة...',
                      border: InputBorder.none,
                    ),
                  ),
                )
                : const Text(
                  'مزادات السيارات',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        // زر تحويل واجهة البحث وإغلاقها
        leading: IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = ''; // تصفير البحث عند الإغلاق
            });
          },
        ),
      ),
      body: Column(
        children: [
          // شريط الفلاتر العلوية
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filterItem = _filters[index];
                final isSelected = _filter == filterItem['value'];
                return GestureDetector(
                  onTap: () => setState(() => _filter = filterItem['value']!),
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF0F4C81)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF0F4C81)
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filterItem['title']!,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // قائمة المزادات المفلترة والمبحوث عنها
          Expanded(
            child:
                finalFilteredAuctions.isEmpty
                    ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'لا توجد مزادات متوفرة في هذا القسم حالياً'
                            : 'لا توجد نتائج تطابق بحثك في هذا القسم',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: finalFilteredAuctions.length,
                      itemBuilder: (context, index) {
                        final auction = finalFilteredAuctions[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AuctionDetailScreen(auction: auction),
                              ),
                            );
                          },
                          child: _buildAuctionCard(auction),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // كرت المزاد
  Widget _buildAuctionCard(Auction auction) {
    final timeRemaining = auction.endTime.difference(DateTime.now());
    final daysRemaining = timeRemaining.inDays;
    final hoursRemaining = timeRemaining.inHours.remainder(24);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child:
                    auction.car.images.isNotEmpty
                        ? Image.network(
                          auction.car.images[0],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Image.asset(
                                'assets/image/intro.jpg',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/image/intro.jpg',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
              ),
              // عداد الوقت
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        auction.status == 'active'
                            ? '${daysRemaining}d ${hoursRemaining}h'
                            : auction.status == 'ended'
                            ? 'انتهى'
                            : 'قريباً',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${auction.car.make} ${auction.car.model} ${auction.car.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          auction.car.location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المزاد الحالي',
                          style: TextStyle(color: Colors.orange, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${auction.currentPrice} ل.س',
                          style: const TextStyle(
                            color: Color(0xFF0F4C81),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'السعر الابتدائي',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${auction.startingPrice} ل.س',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // إحصائيات المزايدة السريعة
                Row(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${auction.bids.length} مزايدة',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
