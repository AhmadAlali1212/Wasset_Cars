import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/mock_data.dart' show MockData;
import 'package:mators_car/widgets/section_header.dart';


class RentalAdsScreen extends StatelessWidget {
  final List<Ad> rentalAds = MockData.rentalAds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعلانات تأجير السيارات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Featured Rental Ads
          if (rentalAds.any((ad) => ad.isFeatured))
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: SectionHeader(
                title: 'إعلانات مميزة',
                onViewAll: () {},
              ),
            ),
          if (rentalAds.any((ad) => ad.isFeatured))
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: rentalAds.where((ad) => ad.isFeatured).length,
                itemBuilder: (context, index) {
                  final ad = rentalAds.where((ad) => ad.isFeatured).toList()[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildFeaturedRentalCard(ad, context),
                  );
                },
              ),
            ),

          // All Rental Ads
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: 'جميع إعلانات التأجير',
              onViewAll: () {},
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rentalAds.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRentalAdCard(rentalAds[index], context),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRentalCard(Ad ad, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RentalAdDetailScreen(ad: ad),
          ),
        );
      },
      child: Container(
        width: 280,
        height: 300, // زيادة الارتفاع لحل مشكلة overflow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ صورة السيارة
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    ad.car.images.isNotEmpty ? ad.car.images[0] : '',
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40),
                      );
                    },
                  ),
                ),
                if (ad.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'مميز',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ✅ معلومات السيارة
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // تقليل المسافة الداخلية
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع المساحة بشكل متساوٍ
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15, // تقليل حجم الخط
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6), // تقليل المسافة
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textSecondary), // تقليل حجم الأيقونة
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                ad.car.location,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11, // تقليل حجم الخط
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ad.dailyPrice} ل.س/يوم',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // تقليل حجم الخط
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${ad.monthlyPrice} ل.س/شهر',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11, // تقليل حجم الخط
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6), // تقليل الحشو
                          decoration: BoxDecoration(
                            color: ad.status == 'pending'
                                ? AppColors.warning.withOpacity(0.2)
                                : AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ad.status == 'pending'
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                          child: Text(
                            ad.status == 'pending' ? 'قيد المراجعة' : 'منشور',
                            style: TextStyle(
                              fontSize: 10, // تقليل حجم الخط
                              fontWeight: FontWeight.bold,
                              color: ad.status == 'pending'
                                  ? AppColors.warning
                                  : AppColors.success,
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


  Widget _buildRentalAdCard(Ad ad, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RentalAdDetailScreen(ad: ad),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Car Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.network(
                ad.car.images.isNotEmpty ? ad.car.images[0] : '',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 30),
                  );
                },
              ),
            ),

            // Car Info - FIXED OVERFLOW
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            ad.car.location,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ad.dailyPrice} ل.س/يوم',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${ad.monthlyPrice} ل.س/شهر',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          decoration: BoxDecoration(
                            color: ad.status == 'pending'
                                ? AppColors.warning.withOpacity(0.2)
                                : AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ad.status == 'pending'
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                          child: Text(
                            ad.status == 'pending' ? 'قيد المراجعة' : 'منشور',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ad.status == 'pending'
                                  ? AppColors.warning
                                  : AppColors.success,
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