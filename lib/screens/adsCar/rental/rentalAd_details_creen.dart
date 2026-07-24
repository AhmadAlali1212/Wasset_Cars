import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/ulits/colors.dart';
import '../../../widgets/auction/car_image_slider.dart';
import '../../../widgets/section_header.dart';

class RentalAdDetailScreen extends StatefulWidget {
  final Ad ad;
  const RentalAdDetailScreen({super.key, required this.ad});

  @override
  State<RentalAdDetailScreen> createState() => _RentalAdDetailScreenState();
}

class _RentalAdDetailScreenState extends State<RentalAdDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'تفاصيل التأجير',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CarImageSlider(images: widget.ad.car.images),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.ad.car.make} ${widget.ad.car.model} ${widget.ad.car.year}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // أزرار عرض السعر المزدوجة المتطابقة مع الصورة تماماً
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'السعر اليومي',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.ad.dailyPrice} ل.س',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'السعر الشهري',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.ad.monthlyPrice} ل.س',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // شبكة الخصائص الثمانية الكاملة للتأجير من الصورة الثالثة
                      _buildEightRentalSpecs(),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'شروط التأجير'),
                      const SizedBox(height: 10),
                      _buildConditionsCheckList(),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'المميزات'),
                      const SizedBox(height: 10),
                      _buildChipsFeatures(),
                      const SizedBox(height: 24),

                      // كارت معلومات المالك مع خريطة مصغرة لموقع استلام السيارة
                      const SectionHeader(
                        title: 'معلومات المؤجر وموقع الاستلام',
                      ),
                      const SizedBox(height: 12),
                      _buildOwnerAndMapCard(),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // كتل أزرار الاتصال والحجز السفلي الذكي والتفاعلي
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      minimumSize: const Size(50, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.phone_outlined, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      minimumSize: const Size(50, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        maximumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'احجز الآن الموعد',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEightRentalSpecs() {
    final items = [
      {
        'title': 'الموقع',
        'val': widget.ad.car.location,
        'icon': Icons.location_on_outlined,
      },
      {
        'title': 'السنة',
        'val': widget.ad.car.year.toString(),
        'icon': Icons.calendar_today_outlined,
      },
      {'title': 'العداد', 'val': '120,000 كم', 'icon': Icons.speed_outlined},
      {
        'title': 'نوع الوقود',
        'val': 'بنزين',
        'icon': Icons.local_gas_station_outlined,
      },
      {'title': 'التأمين', 'val': 'شامل وتام', 'icon': Icons.shield_outlined},
      {'title': 'التكييف', 'val': 'ممتاز', 'icon': Icons.ac_unit},
      {
        'title': 'عدد المقاعد',
        'val': '5 مقاعد',
        'icon': Icons.airline_seat_recline_normal,
      },
      {
        'title': 'ناقل الحركة',
        'val': 'أوتوماتيك',
        'icon': Icons.settings_input_component,
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                items[index]['icon'] as IconData,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                items[index]['val'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                maxLines: 1,
              ),
              Text(
                items[index]['title'] as String,
                style: const TextStyle(color: Colors.grey, fontSize: 8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConditionsCheckList() {
    final conditions = [
      'العمر فوق 21 سنة',
      'رخصة قيادة سارية',
      'تأمين شامل للسيارة',
      'دفع عربون مسترد',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children:
            conditions
                .map(
                  (cond) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cond,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildChipsFeatures() {
    final features = [
      'Bluetooth',
      'GPS',
      'USB',
      'مثبت سرعة',
      'ABS',
      'كاميرا خلفية',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          features
              .map(
                (f) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    f,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildOwnerAndMapCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أحمد علي',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'عضو منذ 2023',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 2),
                  Text(
                    '5.0',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/image/intro.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: const Center(
              child: Icon(Icons.location_pin, color: Colors.red, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}
