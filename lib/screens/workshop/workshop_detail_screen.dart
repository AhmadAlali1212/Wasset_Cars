// screens/workshops/workshop_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/workshop_model.dart';
import 'package:mators_car/widgets/section_header.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/contact_launcher.dart';

class WorkshopDetailScreen extends StatelessWidget {
  final Workshop workshop;

  const WorkshopDetailScreen({super.key, required this.workshop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الورشة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              AppSnackbar.showSuccess(context, title: 'تم تجهيز رابط الورشة للمشاركة');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workshop Images Slider
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: workshop.images.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: workshop.images[index],
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    placeholder:
                        (context, url) => Container(color: Colors.grey.shade200),
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

            // Workshop Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workshop.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        workshop.location,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const SectionHeader(title: 'وصف الورشة'),
                  const SizedBox(height: 8),
                  Text(
                    workshop.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Services
                  const SectionHeader(title: 'الخدمات المتوفرة'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        workshop.services.map((service) {
                          return Chip(
                            label: Text(service),
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            labelStyle: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // Contact Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => ContactLauncher.call(context, workshop.phone),
                      style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'اتصل بالورشة',
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
