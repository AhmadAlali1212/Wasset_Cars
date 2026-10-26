import 'package:flutter/material.dart';

class WizardReviewRow extends StatelessWidget {
  final String title;
  final String value;

  const WizardReviewRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value.isNotEmpty ? value : '-')),
        ],
      ),
    );
  }
}

class CarReviewStep extends StatelessWidget {
  final String make;
  final String model;
  final String year;
  final String location;
  final double? latitude;
  final double? longitude;
  final String condition;
  final String description;
  final int imagesCount;
  final int videosCount;

  const CarReviewStep({
    super.key,
    required this.make,
    required this.model,
    required this.year,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.condition,
    required this.description,
    required this.imagesCount,
    required this.videosCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardReviewRow(title: 'الماركة', value: make),
          WizardReviewRow(title: 'الموديل', value: model),
          WizardReviewRow(title: 'السنة', value: year),
          WizardReviewRow(title: 'الموقع', value: location),
          WizardReviewRow(
            title: 'الإحداثيات',
            value:
                latitude != null && longitude != null
                    ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                    : '',
          ),
          WizardReviewRow(title: 'الحالة', value: condition),
          WizardReviewRow(title: 'الوصف', value: description),
          const SizedBox(height: 16),
          const Text(
            'عدد الصور المختارة',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('$imagesCount صورة'),
          const SizedBox(height: 16),
          const Text(
            'عدد الفيديوهات المختارة',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            videosCount == 0
                ? 'بدون فيديو (يمكنك إضافته لاحقاً من شاشة تعديل السيارة)'
                : '$videosCount فيديو',
          ),
        ],
      ),
    );
  }
}
