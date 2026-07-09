import 'package:flutter/material.dart';
import 'package:mators_car/models/auction_model.dart';
import 'package:mators_car/ulits/colors.dart';

class BidHistoryItem extends StatelessWidget {
  final Bid bid;

  const BidHistoryItem({super.key, required this.bid});

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateTime.now().difference(bid.createdAt);
    String timeText;

    if (timeAgo.inDays > 0) {
      timeText = 'منذ ${timeAgo.inDays} يوم';
    } else if (timeAgo.inHours > 0) {
      timeText = 'منذ ${timeAgo.inHours} ساعة';
    } else {
      timeText = 'منذ ${timeAgo.inMinutes} دقيقة';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مزايد #${bid.userId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${bid.amount} ل.س',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}