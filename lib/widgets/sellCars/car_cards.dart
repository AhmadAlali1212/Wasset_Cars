import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/car_model.dart';
import 'package:mators_car/ulits/colors.dart';

/// ودجات بطاقات السيارات المستخدمة داخل الشاشة الرئيسية (home_ads_screen).
/// استُخرجت من دوال _build... الخاصة بالـ State لتصبح ودجات مستقلة قابلة
/// لإعادة الاستخدام والقراءة بسهولة، دون أي تغيير بالتصميم أو المنطق.

/// بطاقة سيارة داخل شبكة (Grid) — تُستخدم بقسم "كل السيارات" وبنتائج البحث.
class GridCarCard extends StatelessWidget {
  final Car car;
  final double price;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final String Function(double) formatPrice;

  const GridCarCard({
    super.key,
    required this.car,
    required this.price,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final specs = [
      if ((car.fuelType ?? '').isNotEmpty) car.fuelType!,
      if ((car.transmission ?? '').isNotEmpty) car.transmission!,
    ].join(' • ');
    final conditionLabel = car.condition == 'new' ? 'جديدة' : 'مستعملة';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child:
                        car.images.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: car.images[0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              // بطاقة الشبكة بعرض ~180px منطقي فقط، فتحميل
                              // الصورة الأصلية كاملة (قد تصل لعدة ميجابايت)
                              // مبالغ فيه ومكلف جداً بالوقت/الذاكرة.
                              memCacheWidth: 360,
                              placeholder:
                                  (context, url) =>
                                      Container(color: Colors.grey.shade200),
                              errorWidget:
                                  (context, url, error) => Image.asset(
                                    'assets/image/intro.jpg',
                                    fit: BoxFit.cover,
                                  ),
                            )
                            : Image.asset(
                              'assets/image/intro.jpg',
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFavorite ? Colors.red : Colors.black54,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      conditionLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.make} ${car.model} ${car.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (specs.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      specs,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    price > 0 ? formatPrice(price) : 'السعر عند التواصل',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.more_horiz, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          car.userName.isNotEmpty
                              ? '${car.userName} • ${car.location}'
                              : car.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
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

/// بطاقة سيارة عمودية كبيرة (تُستخدم بالقائمة الرئيسية وبنتائج البحث).
/// ملاحظة: بدون onTap داخلياً لأن المستدعين يلفّونها بـ GestureDetector
/// خاص بهم — أبقينا نفس السلوك تماماً كما كان بالكود الأصلي.
class HomeCarCard extends StatelessWidget {
  final Car car;
  final bool hasPromotion;

  const HomeCarCard({super.key, required this.car, required this.hasPromotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child:
                    car.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: car.images[0],
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // بطاقة الكاروسيل الرئيسية بعرض الشاشة تقريباً؛
                          // نحدّد حجم فك ترميز واقعي بدل الصورة الأصلية.
                          memCacheWidth: 800,
                          placeholder:
                              (context, url) => Container(
                                height: 170,
                                color: Colors.grey.shade200,
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/image/intro.jpg',
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/image/intro.jpg',
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
              ),
              if (hasPromotion)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'عليه عرض',
                          style: TextStyle(
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${car.make} ${car.model} ${car.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        car.location.isEmpty ? 'غير محدد' : car.location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (car.condition.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      car.condition,
                      style: const TextStyle(
                        color: Colors.blue,
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
    );
  }
}

/// صف أفقي قابل للتمرير من بطاقات سيارات صغيرة (يُستخدم بأقسام: الأحدث،
/// الجديدة، المستعملة، والمُروّج لها).
class HomeCarsRow extends StatelessWidget {
  final List<Car> cars;
  final void Function(Car car) onCarTap;

  const HomeCarsRow({super.key, required this.cars, required this.onCarTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cars.length,
        itemBuilder: (context, index) {
          final car = cars[index];
          return GestureDetector(
            onTap: () => onCarTap(car),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child:
                        car.images.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: car.images[0],
                              height: 95,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              // بطاقة صف أفقي صغيرة (140px عرضاً)؛ حجم فك
                              // ترميز صغير يكفي تماماً ويوفر الكثير.
                              memCacheWidth: 280,
                              placeholder:
                                  (context, url) => Container(
                                    height: 95,
                                    color: Colors.grey.shade200,
                                  ),
                              errorWidget:
                                  (context, url, error) => Image.asset(
                                    'assets/image/intro.jpg',
                                    height: 95,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                            )
                            : Image.asset(
                              'assets/image/intro.jpg',
                              height: 95,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          car.year > 0 ? car.year.toString() : '',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
