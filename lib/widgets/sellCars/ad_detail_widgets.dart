import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/seller_rating_badge.dart';

/// ودجات استُخرجت من شاشة تفاصيل إعلان البيع (ad_detail_screen.dart)
/// دون أي تغيير بالتصميم أو المنطق.

/// معرض صور الإعلان القابل للتمرير مع عدّاد "1 / N" أسفله.
class AdImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const AdImageGallery({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              return imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    memCacheWidth: 900,
                    placeholder: (context, url) => Container(height: 260, color: Colors.grey.shade200),
                    errorWidget:
                        (context, url, error) =>
                            Image.asset('assets/image/intro.jpg', fit: BoxFit.cover, width: double.infinity),
                  )
                  : Image.asset('assets/image/intro.jpg', fit: BoxFit.cover, width: double.infinity);
            },
          ),
        ),
        Positioned(
          bottom: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.5 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentIndex + 1} / ${images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}

/// شبكة المواصفات الأربعة (نوع الوقود/ناقل الحركة/السنة/العداد).
class AdFourGridSpecs extends StatelessWidget {
  final Ad ad;
  const AdFourGridSpecs({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final specs = [
      {'title': 'نوع الوقود', 'val': ad.car.fuelType ?? 'غير محدد', 'icon': Icons.local_gas_station_outlined},
      {
        'title': 'ناقل الحركة',
        'val': ad.car.transmission ?? 'غير محدد',
        'icon': Icons.settings_input_component_outlined,
      },
      {'title': 'السنة', 'val': ad.car.year.toString(), 'icon': Icons.calendar_today_outlined},
      {
        'title': 'العداد',
        'val': ad.car.mileage != null ? '${ad.car.mileage} كم' : 'غير محدد',
        'icon': Icons.speed_outlined,
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(specs[index]['icon'] as IconData, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(specs[index]['val'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(specs[index]['title'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}

/// بطاقة معلومات البائع الكاملة (اسم + تقييم + أزرار رسالة/واتساب/اتصال).
class AdSellerContactCard extends StatelessWidget {
  final Ad ad;
  final VoidCallback onTapSeller;
  final VoidCallback onTapMessage;
  final VoidCallback onTapWhatsapp;
  final VoidCallback onTapCall;

  const AdSellerContactCard({
    super.key,
    required this.ad,
    required this.onTapSeller,
    required this.onTapMessage,
    required this.onTapWhatsapp,
    required this.onTapCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withAlpha((0.1 * 255).round()),
            child: Icon(Icons.person, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTapSeller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.contactName.isNotEmpty ? ad.contactName : 'مستخدم Syria Motor',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  SellerRatingBadge(userId: ad.userId),
                ],
              ),
            ),
          ),
          // مراسلة حقيقية داخل التطبيق (بديل عملي عن الاعتماد الكامل على
          // واتساب خارجي)
          IconButton(
            onPressed: onTapMessage,
            icon: Icon(Icons.mail_outline, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withAlpha((0.08 * 255).round()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTapWhatsapp,
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withAlpha((0.08 * 255).round()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTapCall,
            icon: Icon(Icons.phone_outlined, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withAlpha((0.08 * 255).round()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط الاتصال والشراء السفلي المدمج (اتصل بالبائع / شراء الآن).
class AdDetailsBottomActionBar extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onBuyNow;

  const AdDetailsBottomActionBar({super.key, required this.onCall, required this.onBuyNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.phone_in_talk, color: Colors.white),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text(
                'اتصل بالبائع',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onBuyNow,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF1F7A3C),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text(
                'شراء الآن',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
