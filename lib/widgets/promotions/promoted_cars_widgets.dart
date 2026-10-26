import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/data/models/promotion_model.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_detail_screen.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/ulits/colors.dart';

/// ودجات وكلاسات بيانات استُخرجت من promoted_cars_screen.dart دون أي
/// تغيير بالتصميم أو المنطق — فقط أصبحت عامة (بدل خاصة بالملف) لتُنقل
/// لملف مستقل.

/// إعلان واحد (بيع أو تأجير) ضمن قسم عرض ترويجي.
class PromotedAd {
  final Ad ad;
  final bool isRental;
  PromotedAd({required this.ad, required this.isRental});
}

/// قسم كامل يمثّل عرضاً ترويجياً واحداً لشركة معيّنة، مع كل إعلاناتها
/// التابعة له.
class PromotedSection {
  final Promotion promotion;
  final String companyName;
  final List<PromotedAd> ads;
  PromotedSection({required this.promotion, required this.companyName, required this.ads});
}

/// بطاقة سيارة صغيرة ضمن صف قسم العرض الترويجي.
class PromotedCarCard extends StatelessWidget {
  final PromotedAd promotedAd;
  const PromotedCarCard({super.key, required this.promotedAd});

  @override
  Widget build(BuildContext context) {
    final ad = promotedAd.ad;
    final car = ad.car;
    final priceText = promotedAd.isRental ? '${ad.dailyPrice} ل.س / يوم' : '${ad.price} ل.س';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child:
                    car.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: car.images[0],
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 350,
                          placeholder: (context, url) => Container(height: 110, color: Colors.grey.shade200),
                          errorWidget:
                              (context, url, error) =>
                                  Image.asset('assets/image/intro.jpg', height: 110, width: double.infinity, fit: BoxFit.cover),
                        )
                        : Image.asset('assets/image/intro.jpg', height: 110, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    'عليه عرض',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${car.make} ${car.model} ${car.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(priceText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم عرض ترويجي كامل: رأس بتدرج لوني (اسم الشركة + عنوان العرض +
/// نسبة الخصم)، سطر معلومات (مدة الانتهاء وعدد السيارات)، ثم صف أفقي
/// من بطاقات السيارات التابعة لهذا العرض.
class PromotedSectionView extends StatelessWidget {
  final PromotedSection section;
  const PromotedSectionView({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final promo = section.promotion;
    final discountLabel =
        promo.type == 'discount' ? 'خصم ${promo.value.toStringAsFixed(0)}%' : promo.value.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        promo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    discountLabel,
                    style: const TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                promo.isExpired ? 'انتهى العرض' : 'ينتهي خلال ${promo.daysRemaining} يوم',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 12),
              Icon(Icons.directions_car, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${section.ads.length} سيارة', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.ads.length,
            itemBuilder: (context, index) {
              final promotedAd = section.ads[index];
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SizedBox(
                  width: 150,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  promotedAd.isRental
                                      ? RentalAdDetailScreen(ad: promotedAd.ad)
                                      : AdDetailScreen(ad: promotedAd.ad),
                        ),
                      );
                    },
                    child: PromotedCarCard(promotedAd: promotedAd),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
