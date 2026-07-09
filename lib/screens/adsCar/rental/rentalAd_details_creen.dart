
import 'package:flutter/material.dart';

import '../../../models/ad_model.dart';
import '../../../ulits/colors.dart' show AppColors;
import '../../../widgets/auction/car_image_slider.dart';
import '../../../widgets/section_header.dart';
import '../compents/car_info_card.dart';

class RentalAdDetailScreen extends StatelessWidget {
  final Ad ad;

  const RentalAdDetailScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الإعلان'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Images Slider
            CarImageSlider(images: ad.car.images),

            // Car Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 15),

                  // Prices - FIXED OVERFLOW
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${ad.dailyPrice} ل.س/يوم',
                            style: const TextStyle(
                              fontSize: 16, // Reduced font size
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12
                          ),
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
                              fontSize: 13, // Reduced font size
                              fontWeight: FontWeight.bold,
                              color: ad.status == 'pending'
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Monthly Price
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'السعر الشهري:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${ad.monthlyPrice} ل.س',
                            style: TextStyle(
                              fontSize: 16, // Reduced font size
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Car Info Cards - FIXED OVERFLOW
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.8, // Increased aspect ratio
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      CarInfoCard(
                        icon: Icons.location_on_outlined,
                        title: 'الموقع',
                        value: ad.car.location,
                      ),
                      CarInfoCard(
                        icon: Icons.car_repair_outlined,
                        title: 'الحالة',
                        value: ad.car.condition == 'used' ? 'مستعمل' : 'جديد',
                      ),
                      CarInfoCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'سنة الصنع',
                        value: ad.car.year.toString(),
                      ),
                      CarInfoCard(
                        icon: Icons.person_outline,
                        title: 'المالك',
                        value: 'محمود السيد',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Rental Conditions
                  const SectionHeader(title: 'شروط التأجير'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ad.rentalConditions,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const SectionHeader(title: 'الوصف'),
                  const SizedBox(height: 10),
                  Text(
                    ad.car.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Contact Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'اتصل بالمؤجر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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