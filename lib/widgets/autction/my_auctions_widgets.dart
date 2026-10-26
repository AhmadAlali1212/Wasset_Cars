import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constans.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';

/// ودجات استُخرجت من شاشة "مزاداتي" (my_auctions_screen.dart) دون أي
/// تغيير بالتصميم أو المنطق.

/// شريحة فلترة واحدة (الكل/نشط/قيد المراجعة/منتهٍ).
class MyAuctionFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MyAuctionFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.adaptiveCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.black12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.adaptiveTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// بطاقة مزاد واحد يملكه المستخدم (صورة + شارة حالة ملوّنة + أعلى مزايدة
/// + عدد المزايدات + أزرار تعديل/حذف، أو زر "عرض التفاصيل" بعد الانتهاء).
class MyAuctionOwnerCard extends StatelessWidget {
  final Auction auction;
  final String statusCategory; // active | pending | ended
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MyAuctionOwnerCard({
    super.key,
    required this.auction,
    required this.statusCategory,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _badgeColor() {
    final s = auction.status.toLowerCase();
    switch (statusCategory) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        if (s.contains('reject') || s.contains('cancel') || s.contains('withdraw')) {
          return Colors.red;
        }
        if (s.contains('complete') || s.contains('sold') || s.contains('done')) {
          return Colors.blue;
        }
        if (s.contains('accept')) return AppColors.primary;
        return Colors.black54;
    }
  }

  String _badgeLabel() {
    final s = auction.status.toLowerCase();
    switch (statusCategory) {
      case 'active':
        return 'نشط';
      case 'pending':
        return 'قيد المراجعة';
      default:
        if (s.contains('reject')) return 'مرفوض';
        if (s.contains('cancel')) return 'ملغى';
        if (s.contains('withdraw')) return 'تراجع الفائز';
        if (s.contains('complete') || s.contains('sold') || s.contains('done')) {
          return 'مكتمل ✅';
        }
        if (s.contains('accept')) return 'بانتظار إتمام البيع';
        return 'منتهٍ - بانتظار قرارك';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConstants.resolveImageUrl(auction.car.images.isNotEmpty ? auction.car.images.first : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child:
                    imageUrl != null
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          memCacheWidth: 168,
                          placeholder: (_, __) => Container(width: 84, height: 84, color: const Color(0xFFF0F0F0)),
                          errorWidget:
                              (_, __, ___) => Container(
                                width: 84,
                                height: 84,
                                color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.directions_car, color: Colors.grey),
                              ),
                        )
                        : Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.directions_car, color: Colors.grey),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${auction.car.make} ${auction.car.model} ${auction.car.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _badgeColor().withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            _badgeLabel(),
                            style: TextStyle(fontSize: 11, color: _badgeColor(), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'أعلى مزايدة: ${auction.currentPrice} ل.س',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text('عدد المزايدات: ${auction.bids.length}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 8),
                    if (statusCategory == 'ended')
                      // بعد انتهاء المزاد لا معنى لتعديله أو حذفه؛ التوجيه
                      // لصفحة التفاصيل حيث تظهر أزرار القبول/الرفض/التأكيد
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.arrow_forward_ios, size: 12),
                          label: const Text('عرض التفاصيل واتخاذ القرار'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.primary),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('تعديل'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              label: const Text('حذف', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: Colors.red),
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
      ),
    );
  }
}
