import 'package:flutter/material.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/ulits/colors.dart';

/// ودجات عرض مستقلة استُخرجت من دوال _build... الخاصة بشاشة تفاصيل المزاد
/// (auction_detail_screen.dart) دون أي تغيير بالتصميم أو المنطق — الهدف
/// فقط تقسيم الشاشة الكبيرة لملفات أصغر وأسهل قراءة.

/// وصف زر إجراء واحد داخل شريط الإجراءات السفلي (قبول/رفض/تأكيد/تراجع).
/// (كانت _ActionButtonSpec خاصة بالملف، أصبحت هنا عامة لإمكانية استيرادها).
class ActionButtonSpec {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const ActionButtonSpec({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });
}

/// الحاوية الموحّدة لكل أشرطة الإجراء السفلية بشاشة المزاد (خلفية بيضاء،
/// حواف علوية دائرية، ظل خفيف).
class BottomSheetContainer extends StatelessWidget {
  final Widget child;
  const BottomSheetContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// شريط تقديم مزايدة جديدة (حقل مبلغ + زر تأكيد).
class BidBar extends StatelessWidget {
  final double minBid;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String Function(double) formatPrice;

  const BidBar({
    super.key,
    required this.minBid,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: formatPrice(minBid),
                  border: InputBorder.none,
                  suffixText: 'ل.س',
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon:
                  isSubmitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(
                        Icons.gavel_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                'قدم المزايدة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر إجراء رئيسي واحد (تأكيد إتمام البيع) أو زوج أزرار (قبول/رفض).
class ActionButtonsBar extends StatelessWidget {
  final List<ActionButtonSpec> buttons;
  final bool isProcessing;

  const ActionButtonsBar({
    super.key,
    required this.buttons,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child:
                  buttons[i].filled
                      ? ElevatedButton.icon(
                        onPressed: isProcessing ? null : buttons[i].onTap,
                        icon: Icon(
                          buttons[i].icon,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          buttons[i].label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: buttons[i].color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                      : OutlinedButton.icon(
                        onPressed: isProcessing ? null : buttons[i].onTap,
                        icon: Icon(
                          buttons[i].icon,
                          color: buttons[i].color,
                          size: 18,
                        ),
                        label: Text(
                          buttons[i].label,
                          style: TextStyle(
                            color: buttons[i].color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: buttons[i].color),
                        ),
                      ),
            ),
          ],
        ],
      ),
    );
  }
}

/// شريط معلوماتي بلا إجراء (لغير البائع/الفائز، أو للفائز أثناء انتظار قرار
/// البائع، أو بعد اكتمال/رفض/إلغاء الصفقة).
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// نفس شريط المعلومات، مع زر "تحديث" لإعادة جلب حالة المزاد من السيرفر
/// يدوياً؛ يُستخدم في حالة انتهاء العدّاد محلياً بانتظار إغلاق حقيقي.
class InfoBannerWithRefresh extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const InfoBannerWithRefresh({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: isRefreshing ? null : onRefresh,
            icon:
                isRefreshing
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh, size: 16),
            label: const Text('تحديث', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// شارة حالة المزاد (مباشر/قيد المراجعة/مكتمل/... إلخ) — حساب اللون والنص
/// والنبض حسب المرحلة يبقى بالشاشة نفسها (منطق عمل)، وهذه الودجت فقط
/// مسؤولة عن رسم الشارة.
class LiveBadge extends StatelessWidget {
  final Color color;
  final String label;
  final bool pulsing;

  const LiveBadge({
    super.key,
    required this.color,
    required this.label,
    required this.pulsing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (pulsing)
            const CircleAvatar(radius: 4, backgroundColor: Colors.white)
          else
            const Icon(Icons.circle, size: 8, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// وحدة دائرية واحدة من العدّاد التنازلي (مثال: "12" فوق "يوم").
class TimeCircularUnit extends StatelessWidget {
  final String value;
  final String label;
  const TimeCircularUnit({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

/// شبكة مواصفات السيارة (البائع/الموقع/السنة/العداد) أعلى تفاصيل المزاد.
class AuctionGridSpecs extends StatelessWidget {
  final Auction auction;
  const AuctionGridSpecs({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'البائع',
        'val': auction.car.userName,
        'icon': Icons.person_outline,
      },
      {
        'title': 'الموقع',
        'val': auction.car.location,
        'icon': Icons.location_on_outlined,
      },
      {
        'title': 'السنة',
        'val': auction.car.year.toString(),
        'icon': Icons.calendar_today_outlined,
      },
      {'title': 'العداد', 'val': '120,000 كم', 'icon': Icons.speed_outlined},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Icon(
                items[index]['icon'] as IconData,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      items[index]['val'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      items[index]['title'] as String,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// قائمة المزايدات الحقيقية القادمة من الـ API (الأحدث أولاً).
class BidsList extends StatelessWidget {
  final List<Bid> bids;
  final String Function(double) formatPrice;
  final double Function(String) parsePrice;
  final String Function(DateTime) formatDateTime;

  const BidsList({
    super.key,
    required this.bids,
    required this.formatPrice,
    required this.parsePrice,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final sortedBids = List.of(bids)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (sortedBids.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'لا توجد مزايدات بعد، كن أول من يزايد!',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedBids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bid = sortedBids[index];
        final isTop = index == 0;
        final displayName =
            bid.userName.isNotEmpty ? bid.userName : 'مستخدم #${bid.userId}';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      formatDateTime(bid.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrice(parsePrice(bid.amount)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (isTop)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'أعلى مزايدة',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
