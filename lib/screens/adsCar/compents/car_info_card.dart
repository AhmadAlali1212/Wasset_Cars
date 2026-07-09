import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

class CarInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const CarInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // تقليل المساحة العمودية
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // تغيير المحاذاة
        children: [
          // Icon Container
          Container(
            width: 30, // تقليل الحجم
            height: 30, // تقليل الحجم
            margin: const EdgeInsets.only(top: 1), // تعديل طفيف للمسافة
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 16), // تقليل حجم الأيقونة
          ),
          const SizedBox(width: 8), // تقليل المسافة

          // Text Content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10, // تقليل حجم الخط
                    color: AppColors.textSecondary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2), // تقليل المسافة بين العنوان والقيمة

                // Value
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12, // تقليل حجم الخط
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.0, // ضبط ارتفاع السطر
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