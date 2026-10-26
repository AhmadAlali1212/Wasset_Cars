import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

/// ودجات استُخرجت من شاشة المزادات (auctions_screen.dart) دون أي تغيير
/// بالتصميم أو المنطق.

/// صف تبويبات الفلترة الأفقي (نشطة/قادمة/منتهية).
class AuctionsFilterTabs extends StatelessWidget {
  final List<Map<String, String>> filters;
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const AuctionsFilterTabs({
    super.key,
    required this.filters,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: context.adaptiveCardBg,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filterItem = filters[index];
          final isSelected = selectedValue == filterItem['value'];
          return GestureDetector(
            onTap: () => onSelect(filterItem['value']!),
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F4C81) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF0F4C81) : Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  switch (filterItem['value']) {
                    'active' => context.tr('active'),
                    'upcoming' => context.tr('upcoming'),
                    _ => context.tr('ended'),
                  },
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// بطاقة مزاد واحدة بالقائمة العامة (صورة + عنوان + موقع + السعر الحالي
/// والابتدائي + عدد المزايدات).
class AuctionCard extends StatelessWidget {
  final Auction auction;
  const AuctionCard({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child:
                auction.car.images.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: auction.car.images[0],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (context, url) => Container(height: 180, color: Colors.grey.shade200),
                      errorWidget:
                          (context, url, error) =>
                              Image.asset('assets/image/intro.jpg', height: 180, width: double.infinity, fit: BoxFit.cover),
                    )
                    : Image.asset('assets/image/intro.jpg', height: 180, width: double.infinity, fit: BoxFit.cover),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(auction.car.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                        const Text('المزاد الحالي', style: TextStyle(color: Colors.orange, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${auction.currentPrice} ل.س',
                          style: const TextStyle(color: Color(0xFF0F4C81), fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('السعر الابتدائي', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${auction.startingPrice} ل.س',
                          style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.gavel_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${auction.bids.length} مزايدة', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
