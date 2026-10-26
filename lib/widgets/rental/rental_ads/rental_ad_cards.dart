import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';

/// ودجات بطاقات إعلانات التأجير — استُخرجت من دوال _build... الخاصة
/// بشاشة rentalAds_screen.dart دون أي تغيير بالتصميم أو المنطق.

/// صورة إعلان مع placeholder وصورة بديلة عند الفشل، وحجم فك ترميز محسوب
/// حسب العرض الفعلي بدل تحميل الصورة الأصلية كاملة دائماً.
class RentalAdImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const RentalAdImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        // نحدد حجم فك الترميز حسب عرض العرض الفعلي إن كان معروفاً، بحد
        // أقصى معقول، بدل تحميل الصورة الأصلية كاملة دائماً.
        memCacheWidth:
            (width != null && width!.isFinite) ? (width! * 2).round() : 600,
        placeholder: (context, url) => Container(color: Colors.grey.shade200),
        errorWidget: (context, url, error) {
          return Image.asset(
            'assets/image/intro.jpg',
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }
    return Image.asset('assets/image/intro.jpg', width: width, height: height, fit: fit);
  }
}

/// الكرت المميز الكبير (قسم "إعلانات مميزة" الأفقي أعلى الشاشة).
class FeaturedRentalCard extends StatelessWidget {
  final Ad ad;
  final VoidCallback onTap;

  const FeaturedRentalCard({super.key, required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: context.adaptiveCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: RentalAdImage(
                    imageUrl: ad.car.images.isNotEmpty ? ad.car.images[0] : null,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'مميز',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 12,
                  left: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Icon(Icons.favorite_border, color: Colors.black, size: 18),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '1 / ${ad.car.images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ل.س ${ad.dailyPrice} / يوم',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ad.car.location,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'أو ل.س ${ad.monthlyPrice} / شهر',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          ad.status == 'pending'
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ad.status == 'pending' ? 'قيد المراجعة' : 'متوفر',
                      style: TextStyle(
                        color: ad.status == 'pending' ? AppColors.warning : AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الكرت الصغير الأفقي لعنصر واحد ضمن قائمة "جميع إعلانات التأجير".
class RentalAdCard extends StatelessWidget {
  final Ad ad;
  final VoidCallback onTap;

  const RentalAdCard({super.key, required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: RentalAdImage(
                    imageUrl: ad.car.images.isNotEmpty ? ad.car.images[0] : null,
                    width: 130,
                    height: 115,
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 12,
                    child: Icon(Icons.favorite_border, size: 14, color: Colors.black),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '1 / ${ad.car.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            ad.car.location,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ل.س ${ad.dailyPrice} / يوم',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'أو ل.س ${ad.monthlyPrice} / شهر',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                ad.status == 'pending'
                                    ? AppColors.warning.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ad.status == 'pending' ? 'قيد المراجعة' : 'متوفر',
                            style: TextStyle(
                              color:
                                  ad.status == 'pending' ? AppColors.warning : AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
