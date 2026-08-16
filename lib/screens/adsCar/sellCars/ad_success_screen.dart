import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/compents/car_info_card.dart';
import 'package:mators_car/ulits/colors.dart';
import '../compents/car_image_slider.dart';

class AdSuccessScreen extends StatelessWidget {
  final Ad ad;

  const AdSuccessScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تمت إضافة الإعلان'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success Message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha((0.1 * 255).round()),
                border: Border(
                  bottom: BorderSide(color: AppColors.success, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'تم إضافة إعلان البيع بنجاح. سيتم مراجعته قبل النشر.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Car Images Slider
            CarImageSlider(images: ad.car.images),

            // Car Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Price
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${ad.price} ل.س',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              ad.status == 'pending'
                                  ? AppColors.warning.withAlpha(
                                    (0.2 * 255).round(),
                                  )
                                  : AppColors.success.withAlpha(
                                    (0.2 * 255).round(),
                                  ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                ad.status == 'pending'
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                        child: Text(
                          ad.status == 'pending' ? 'قيد المراجعة' : 'منشور',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                ad.status == 'pending'
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Car Info Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.5,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
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

                  // Description
                  Text(
                    'الوصف:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.car.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Edit ad
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'تعديل الإعلان',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'العودة للرئيسية',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
