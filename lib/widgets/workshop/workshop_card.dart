import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/ulits/colors.dart';

import '../../models/workshop_model.dart';

class WorkshopCard extends StatelessWidget {
  final Workshop workshop;
  final VoidCallback? onTap;

  const WorkshopCard({super.key, required this.workshop, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6, // ارتفاع أقصى
        ),
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
        child: SingleChildScrollView( // إضافة إمكانية التمرير
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // مهم لمنع التجاوز
            children: [
              // Workshop Images Slider
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio( // تحديد نسبة ثابتة للصور
                  aspectRatio: 16/9,
                  child: PageView.builder(
                    itemCount: workshop.images.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: workshop.images[index],
                        fit: BoxFit.cover,
                        memCacheWidth: 700,
                        placeholder: (context, url) => Container(color: Colors.grey.shade200),
                        errorWidget: (context, url, error) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 50),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Workshop Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workshop.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2, // تحديد عدد الأسطر
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded( // لمنع تجاوز النص
                          child: Text(
                            workshop.location,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Services
                    Text(
                      'الخدمات المتوفرة:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // قائمة الخدمات مع تحديد ارتفاع ثابت
                    SizedBox(
                      height: 100, // ارتفاع ثابت للخدمات
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: workshop.services.map((service) {
                            return Chip(
                              label: Text(service),
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}