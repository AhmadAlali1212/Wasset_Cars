import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/compents/car_image_slider.dart';
import 'package:mators_car/screens/adsCar/compents/car_info_card.dart';
import 'package:mators_car/ulits/colors.dart';

class RentalAdSuccessScreen extends StatelessWidget {
  final Ad ad;

  const RentalAdSuccessScreen({super.key, required this.ad});

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
            // رسالة النجاح
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
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
                      'تم إضافة إعلان التأجير بنجاح. سيتم مراجعته قبل النشر.',
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

            // صور السيارة
            CarImageSlider(images: ad.car.images),

            // تفاصيل السيارة
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // الأسعار والحالة
                  Row(
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
                          '${ad.price} ل.س/يوم',
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ad.status == 'pending'
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // السعر الشهري
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
                        Text(
                          'السعر الشهري:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${ad.monthlyPrice} ل.س',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // معلومات السيارة
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
                        value: ad.location,
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
                        icon: Icons.description_outlined,
                        title: 'شروط التأجير',
                        value: ad.rentalConditions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // الوصف
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

                  // الأزرار
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: تعديل الإعلان
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
                            Navigator.popUntil(context, (route) => route.isFirst);
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