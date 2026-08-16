import 'package:flutter/material.dart';
import 'package:mators_car/services/rating_service.dart';

/// شارة تقييم صغيرة تُحمّل متوسط تقييمات مستخدم حقيقي من الـ API
/// (GET /users/{id}/ratings) بدل الأرقام الثابتة الوهمية التي كانت
/// موجودة بالتصميم الأصلي (مثل "4.9 (128 تقييم)").
class SellerRatingBadge extends StatefulWidget {
  final int userId;
  final double iconSize;
  final double fontSize;

  const SellerRatingBadge({
    super.key,
    required this.userId,
    this.iconSize = 16,
    this.fontSize = 12,
  });

  @override
  State<SellerRatingBadge> createState() => _SellerRatingBadgeState();
}

class _SellerRatingBadgeState extends State<SellerRatingBadge> {
  final RatingService _ratingService = RatingService();
  late Future<List<Map<String, dynamic>>> _ratingsFuture;

  @override
  void initState() {
    super.initState();
    _ratingsFuture =
        widget.userId == 0
            ? Future.value(const [])
            : _ratingService.getRatings(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ratingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final ratings = snapshot.data ?? const [];
        if (ratings.isEmpty) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_border,
                color: Colors.grey.shade400,
                size: widget.iconSize,
              ),
              const SizedBox(width: 4),
              Text(
                'لا توجد تقييمات بعد',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: widget.fontSize,
                ),
              ),
            ],
          );
        }

        final values =
            ratings
                .map((r) => double.tryParse('${r['rating'] ?? 0}') ?? 0)
                .toList();
        final average = values.reduce((a, b) => a + b) / values.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: widget.iconSize),
            const SizedBox(width: 4),
            Text(
              '${average.toStringAsFixed(1)} (${ratings.length} تقييم)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: widget.fontSize,
              ),
            ),
          ],
        );
      },
    );
  }
}
