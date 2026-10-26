import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/rating_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/screens/disputes/raise_dispute_screen.dart';

/// شاشة "تقييمات معلّقة" — تعرض بالضبط المعاملات المكتملة (بيع/مزاد/حجز
/// تأجير) التي يحق للمستخدم تقييمها ولم يفعل بعد، عبر /ratings/ratable.
/// أفضل بكثير من زر "قيّم" حر بلا سياق: كل عنصر هنا معاملة حقيقية.
class PendingRatingsScreen extends StatefulWidget {
  const PendingRatingsScreen({super.key});

  @override
  State<PendingRatingsScreen> createState() => _PendingRatingsScreenState();
}

class _PendingRatingsScreenState extends State<PendingRatingsScreen> {
  final RatingService _ratingService = RatingService();
  late Future<List<Map<String, dynamic>>> _ratableFuture;

  @override
  void initState() {
    super.initState();
    _ratableFuture = _ratingService.getRatableTransactions();
  }

  Future<void> _refresh() async {
    setState(() {
      _ratableFuture = _ratingService.getRatableTransactions();
    });
    await _ratableFuture;
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'ad':
        return 'صفقة بيع';
      case 'auction':
        return 'مزاد';
      case 'rental_booking':
        return 'حجز تأجير';
      default:
        return 'معاملة';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ad':
        return Icons.sell_outlined;
      case 'auction':
        return Icons.gavel_outlined;
      case 'rental_booking':
        return Icons.car_rental_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _rate(Map<String, dynamic> transaction) async {
    final otherUserId = (transaction['other_user_id'] as num?)?.toInt();
    final otherUserName =
        transaction['other_user_name']?.toString() ?? 'المستخدم الآخر';
    if (otherUserId == null) return;

    int selectedStars = 5;
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('قيّم $otherUserName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    transaction['title']?.toString() ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return IconButton(
                        onPressed:
                            () =>
                                setDialogState(() => selectedStars = starIndex),
                        icon: Icon(
                          starIndex <= selectedStars
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'اكتب تعليقك (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'إرسال',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await _ratingService.addRating(
        userId: otherUserId,
        rating: selectedStars,
        comment:
            commentController.text.trim().isEmpty
                ? null
                : commentController.text.trim(),
        type: transaction['type'] as String,
        transactionId: (transaction['transaction_id'] as num).toInt(),
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تم إرسال تقييمك بنجاح');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر إرسال التقييم',
        debugMessage: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'تقييمات معلّقة',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ratableFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 5);
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'تعذر جلب التقييمات المعلّقة\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final ratable = snapshot.data ?? [];
            if (ratable.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.task_alt, size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد تقييمات معلّقة حالياً')),
                  SizedBox(height: 4),
                  Center(
                    child: Text(
                      'ستظهر هنا أي صفقة بيع أو مزاد أو حجز تأجير تكتمل معك',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ratable.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final t = ratable[index];
                final type = t['type']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_typeIcon(type), color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['title']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_typeLabel(type)} — مع ${t['other_user_name'] ?? 'مستخدم'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _rate(t),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(64, 34),
                            ),
                            child: const Text(
                              'قيّم',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // ⬅️ جديد: رفع نزاع مباشرة من نفس المعاملة، بدل
                          // إجبار المستخدم يمر بشاشة أخرى للوصول لهذه البيانات.
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => RaiseDisputeScreen(
                                        againstUserId:
                                            (t['other_user_id'] as num).toInt(),
                                        againstUserName:
                                            t['other_user_name']?.toString() ??
                                            'المستخدم',
                                        transactionType: type,
                                        transactionId:
                                            (t['transaction_id'] as num)
                                                .toInt(),
                                        transactionTitle:
                                            t['title']?.toString() ?? '',
                                      ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              minimumSize: const Size(64, 24),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'لدي مشكلة',
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
