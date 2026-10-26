import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/car_model.dart';
import 'package:mators_car/data/models/rating_model.dart';
import 'package:mators_car/ulits/colors.dart';

/// ودجات استُخرجت من دوال _build... الخاصة بشاشة الملف العام للشركة
/// (company_public_profile_screen.dart) دون أي تغيير بالتصميم أو المنطق.

/// عنوان قسم بشارة صغيرة ملوّنة قبل النص (نمط موحّد لكل عناوين الأقسام
/// بهذه الشاشة: "السيارات المميزة"، "التقييمات"، ...).
class SectionTitleBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  const SectionTitleBadge({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}

/// عنصر إحصائية واحد (أيقونة + قيمة + تسمية)، يُستخدم ثلاث مرات بصف
/// الإحصائيات أعلى الشاشة (متابعون/سيارات/تقييم).
class CompanyStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const CompanyStatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// فاصل عمودي رفيع بين عناصر صف الإحصائيات.
class CompanyStatDivider extends StatelessWidget {
  const CompanyStatDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

/// صف الإحصائيات الكامل: متابعون / عدد السيارات / متوسط التقييم.
class CompanyStatsRow extends StatelessWidget {
  final Future<List<Car>> carsFuture;
  final Future<List<Rating>> ratingsFuture;
  final Object? followersCount;

  const CompanyStatsRow({
    super.key,
    required this.carsFuture,
    required this.ratingsFuture,
    required this.followersCount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Car>>(
      future: carsFuture,
      builder: (context, carsSnapshot) {
        final carsCount = carsSnapshot.data?.length;
        return FutureBuilder<List<Rating>>(
          future: ratingsFuture,
          builder: (context, ratingsSnapshot) {
            final ratings = ratingsSnapshot.data;
            String ratingText = '...';
            if (ratings != null) {
              ratingText =
                  ratings.isEmpty
                      ? '—'
                      : (ratings.map((r) => r.value).reduce((a, b) => a + b) /
                              ratings.length)
                          .toStringAsFixed(1);
            }
            final ratingsCount = ratings?.length;
            return Row(
              children: [
                CompanyStatItem(
                  icon: Icons.people_alt_outlined,
                  value: followersCount != null ? followersCount.toString() : '—',
                  label: 'متابع',
                ),
                const CompanyStatDivider(),
                CompanyStatItem(
                  icon: Icons.directions_car_filled_outlined,
                  value: carsCount != null ? carsCount.toString() : '...',
                  label: 'سيارة للبيع',
                ),
                const CompanyStatDivider(),
                CompanyStatItem(
                  icon: Icons.star_rounded,
                  value: ratingText,
                  label:
                      ratingsCount != null && ratingsCount > 0
                          ? 'تقييم ($ratingsCount)'
                          : 'تقييم',
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// قسم "السيارات المميزة": صف أفقي من أول 8 سيارات لدى الشركة.
class FeaturedCarsSection extends StatelessWidget {
  final Future<List<Car>> carsFuture;
  const FeaturedCarsSection({super.key, required this.carsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Car>>(
      future: carsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final cars = snapshot.data ?? [];
        if (cars.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitleBadge(
              icon: Icons.directions_car_filled,
              title: 'السيارات المميزة',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cars.length > 8 ? 8 : cars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final car = cars[index];
                  final imageUrl =
                      car.images.isNotEmpty ? car.images.first : null;
                  return Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          child:
                              imageUrl != null
                                  ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 300,
                                    placeholder:
                                        (_, __) => Container(
                                          height: 100,
                                          color: const Color(0xFFF0F0F0),
                                        ),
                                    errorWidget:
                                        (_, __, ___) => Container(
                                          height: 100,
                                          color: const Color(0xFFF0F0F0),
                                        ),
                                  )
                                  : Container(
                                    height: 100,
                                    color: const Color(0xFFF0F0F0),
                                    child: const Icon(Icons.directions_car),
                                  ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${car.make} ${car.model}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${car.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// بطاقة تقييم واحدة (اسم المُقيِّم + عدد النجوم + التعليق إن وُجد).
class CompanyRatingItem extends StatelessWidget {
  final Rating rating;
  const CompanyRatingItem({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final initial = rating.raterName.isNotEmpty ? rating.raterName[0] : '؟';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rating.raterName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.value ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 42),
              child: Text(
                rating.comment,
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// قسم "التقييمات" كاملاً: عنوان + زر "قيّم هذه الشركة" + قائمة أول 6
/// تقييمات أو رسالة "لا توجد تقييمات بعد".
class CompanyRatingsSection extends StatelessWidget {
  final Future<List<Rating>> ratingsFuture;
  final VoidCallback onRate;

  const CompanyRatingsSection({
    super.key,
    required this.ratingsFuture,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Rating>>(
      future: ratingsFuture,
      builder: (context, snapshot) {
        final ratings = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitleBadge(icon: Icons.star_rounded, title: 'التقييمات'),
                TextButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.star_border, size: 18),
                  label: const Text('قيّم هذه الشركة'),
                ),
              ],
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (ratings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'لا توجد تقييمات بعد. كن أول من يقيّم!',
                  style: TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
              )
            else
              ...ratings.take(6).map((r) => CompanyRatingItem(rating: r)),
          ],
        );
      },
    );
  }
}
