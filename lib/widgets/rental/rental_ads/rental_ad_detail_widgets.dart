import 'package:flutter/material.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/seller_rating_badge.dart';

/// ودجات استُخرجت من دوال _build... الخاصة بشاشة تفاصيل إعلان التأجير
/// (rentalAd_details_creen.dart) دون أي تغيير بالتصميم أو المنطق.

/// صف عرض السعرين (يومي بخلفية معبّأة، شهري بخلفية شفافة) أعلى الشاشة.
class RentalPriceRow extends StatelessWidget {
  final String dailyPrice;
  final String monthlyPrice;

  const RentalPriceRow({super.key, required this.dailyPrice, required this.monthlyPrice});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dailyPrice ل.س',
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
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('السعر الشهري', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '$monthlyPrice ل.س',
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
    );
  }
}

/// شبكة الخصائص الثمانية للتأجير (الموقع/السنة/العداد/الوقود/التأمين/
/// التكييف/المقاعد/ناقل الحركة).
class RentalEightSpecsGrid extends StatelessWidget {
  final Ad ad;
  const RentalEightSpecsGrid({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'الموقع', 'val': ad.car.location, 'icon': Icons.location_on_outlined},
      {'title': 'السنة', 'val': ad.car.year.toString(), 'icon': Icons.calendar_today_outlined},
      {
        'title': 'العداد',
        'val': ad.car.mileage != null ? '${ad.car.mileage} كم' : 'غير محدد',
        'icon': Icons.speed_outlined,
      },
      {
        'title': 'نوع الوقود',
        'val': ad.car.fuelType ?? 'غير محدد',
        'icon': Icons.local_gas_station_outlined,
      },
      {'title': 'التأمين', 'val': 'شامل وتام', 'icon': Icons.shield_outlined},
      {'title': 'التكييف', 'val': 'ممتاز', 'icon': Icons.ac_unit},
      {'title': 'عدد المقاعد', 'val': '5 مقاعد', 'icon': Icons.airline_seat_recline_normal},
      {
        'title': 'ناقل الحركة',
        'val': ad.car.transmission ?? 'غير محدد',
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[index]['icon'] as IconData, color: AppColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                items[index]['val'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
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
}

/// قائمة تحقّق بشروط التأجير (ثابتة حالياً بانتظار ربطها ببيانات حقيقية
/// من الـ API).
class RentalConditionsChecklist extends StatelessWidget {
  const RentalConditionsChecklist({super.key});

  static const List<String> _conditions = [
    'العمر فوق 21 سنة',
    'رخصة قيادة سارية',
    'تأمين شامل للسيارة',
    'دفع عربون مسترد',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children:
            _conditions
                .map(
                  (cond) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cond, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

/// شرائح مميزات السيارة (ثابتة حالياً بانتظار ربطها ببيانات حقيقية من
/// الـ API).
class RentalFeatureChips extends StatelessWidget {
  const RentalFeatureChips({super.key});

  static const List<String> _features = ['Bluetooth', 'GPS', 'USB', 'مثبت سرعة', 'ABS', 'كاميرا خلفية'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _features
              .map(
                (f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(f, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ),
              )
              .toList(),
    );
  }
}

/// بطاقة معلومات المؤجر (اسم + تقييم) مع خريطة مصغّرة لموقع الاستلام.
class RentalOwnerAndMapCard extends StatelessWidget {
  final Ad ad;
  final VoidCallback onTapOwner;
  final VoidCallback onTapMap;

  const RentalOwnerAndMapCard({
    super.key,
    required this.ad,
    required this.onTapOwner,
    required this.onTapMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapOwner,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.contactName.isNotEmpty ? ad.contactName : 'مستخدم Syria Motor',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SellerRatingBadge(userId: ad.userId, fontSize: 11),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTapMap,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
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
          ),
        ],
      ),
    );
  }
}

/// شريط الإجراءات السفلي (رسالة/واتساب/اتصال/زر حجز).
class RentalDetailsBottomActionBar extends StatelessWidget {
  final bool isBooking;
  final VoidCallback onMessage;
  final VoidCallback onWhatsapp;
  final VoidCallback onCall;
  final VoidCallback onBookNow;

  const RentalDetailsBottomActionBar({
    super.key,
    required this.isBooking,
    required this.onMessage,
    required this.onWhatsapp,
    required this.onCall,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMessage,
            icon: Icon(Icons.mail_outline, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              minimumSize: const Size(50, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onWhatsapp,
            icon: Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              minimumSize: const Size(50, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onCall,
            icon: Icon(Icons.phone_outlined, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              minimumSize: const Size(50, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isBooking ? null : onBookNow,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                maximumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  isBooking
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                      : const Text(
                        'احجز الآن الموعد',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
