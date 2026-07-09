import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/section_header.dart';

class AdDetailScreen extends StatelessWidget {
  final Ad ad;

  const AdDetailScreen({super.key, required this.ad});

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
            // Car Images Gallery
            _buildImageGallery(),

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
                  ),
                  const SizedBox(height: 10),

                  // Price and Status
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
                  const SizedBox(height: 20),

                  // Car Info
                  const SectionHeader(title: 'معلومات السيارة'),
                  const SizedBox(height: 10),
                  _buildCarInfoTable(),

                  // Description
                  const SizedBox(height: 20),
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

                  // Contact Seller
                  const SizedBox(height: 30),
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
                        'اتصل بالبائع',
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

  Widget _buildImageGallery() {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: ad.car.images.length,
        itemBuilder: (context, index) {
          return Image.network(
            ad.car.images[index],
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget _buildCarInfoTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(2),
      },
      children: [
        _buildTableRow('الماركة', ad.car.make),
        _buildTableRow('الموديل', ad.car.model),
        _buildTableRow('سنة الصنع', ad.car.year.toString()),
        _buildTableRow('الحالة', ad.car.condition == 'used' ? 'مستعمل' : 'جديد'),
        _buildTableRow('الموقع', ad.car.location),
        _buildTableRow('تاريخ الإضافة', _formatDate(ad.createdAt)),
      ],
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceDark,
            width: 1,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}