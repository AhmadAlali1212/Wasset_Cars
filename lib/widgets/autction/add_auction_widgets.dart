import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constant.dart';
import 'package:mators_car/services/api_exception.dart';

/// ودجات استُخرجت من دوال _build... الخاصة بشاشة إنشاء/تعديل المزاد
/// (add_auction_screen.dart) دون أي تغيير بالتصميم أو المنطق.

/// شريط تنبيه أعلى الشاشة يوضّح أن إنشاء مزاد يتطلب اشتراكاً نشطاً.
class AuctionSubscriptionBanner extends StatelessWidget {
  final VoidCallback onSubscribeTap;
  const AuctionSubscriptionBanner({super.key, required this.onSubscribeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'يتطلب إنشاء مزاد اشتراكاً نشطاً',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: onSubscribeTap,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'اشترك الآن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// مؤشر خطوات معالج إنشاء المزاد (يخفي خطوة "اختيار السيارة" في وضع
/// التعديل، لأن السيارة تبقى مثبّتة).
class AuctionStepper extends StatelessWidget {
  final List<String> steps;
  final int step;
  final bool isEditing;

  const AuctionStepper({
    super.key,
    required this.steps,
    required this.step,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    // بوضع التعديل نعرض فقط خطوتي التفاصيل والمراجعة (السيارة مثبّتة)
    final visibleSteps = isEditing ? steps.sublist(1) : steps;
    final activeIndex = isEditing ? step - 1 : step;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(visibleSteps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < activeIndex;
            return Container(
              width: 40,
              height: 2,
              color: leftDone ? AppColors.primary : Colors.grey.shade300,
            );
          }
          final index = i ~/ 2;
          final isDone = index < activeIndex;
          final isCurrent = index == activeIndex;
          return CircleAvatar(
            radius: 14,
            backgroundColor:
                isDone || isCurrent ? AppColors.primary : Colors.grey.shade300,
            child:
                isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          );
        }),
      ),
    );
  }
}

/// نص خطأ موحّد يظهر أسفل أي خطوة عند فشل التحقق أو الإرسال.
class AuctionErrorText extends StatelessWidget {
  final String message;
  const AuctionErrorText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }
}

/// خطوة "اختيار السيارة": قائمة سيارات المستخدم المعتمدة القابلة لطرح
/// مزاد عليها.
class AuctionCarStep extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> carsFuture;
  final Map<String, dynamic>? selectedCar;
  final void Function(Map<String, dynamic> car) onSelectCar;
  final String? errorMessage;

  const AuctionCarStep({
    super.key,
    required this.carsFuture,
    required this.selectedCar,
    required this.onSelectCar,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: carsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              'تعذر جلب سياراتك\n'
              '${ApiException.userMessage(snapshot.error)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final cars = snapshot.data ?? [];
        if (cars.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              'لا توجد لديك سيارات معتمدة بعد. أضف سيارة وانتظر اعتمادها '
              'من الإدارة قبل إنشاء مزاد عليها.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر السيارة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...cars.map((car) {
              final selected =
                  selectedCar != null && selectedCar!['id'] == car['id'];
              final imageUrl = AppConstants.resolveImageUrl(
                car['images'] is List && (car['images'] as List).isNotEmpty
                    ? (car['images'] as List).first.toString()
                    : null,
              );
              return GestureDetector(
                onTap: () => onSelectCar(car),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.black12,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            imageUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 112,
                                  placeholder:
                                      (_, __) => Container(
                                        width: 56,
                                        height: 56,
                                        color: const Color(0xFFF0F0F0),
                                      ),
                                  errorWidget:
                                      (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: const Color(0xFFF0F0F0),
                                      ),
                                )
                                : Container(
                                  width: 56,
                                  height: 56,
                                  color: const Color(0xFFF0F0F0),
                                  child: const Icon(Icons.directions_car),
                                ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${car['make'] ?? ''} ${car['model'] ?? ''} ${car['year'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected ? AppColors.primary : Colors.black26,
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (errorMessage != null) AuctionErrorText(message: errorMessage!),
          ],
        );
      },
    );
  }
}

/// خطوة "تفاصيل المزاد": السعر الابتدائي ومدة المزاد بالساعات.
class AuctionDetailsStep extends StatelessWidget {
  final TextEditingController startingPriceController;
  final TextEditingController durationController;
  final String? errorMessage;

  const AuctionDetailsStep({
    super.key,
    required this.startingPriceController,
    required this.durationController,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل المزاد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        const Text('السعر الابتدائي (ل.س)'),
        const SizedBox(height: 6),
        TextField(
          controller: startingPriceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'مثال: 20000000',
          ),
        ),
        const SizedBox(height: 16),
        const Text('مدة المزاد (بالساعات)'),
        const SizedBox(height: 6),
        TextField(
          controller: durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'مثال: 24',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'على المزايدين حجز عربون من محفظتهم عند المزايدة، بنسبة '
                  'تحددها إعدادات المنصة.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        if (errorMessage != null) AuctionErrorText(message: errorMessage!),
      ],
    );
  }
}

/// صف واحد بخطوة المراجعة (تسمية + قيمة).
class AuctionReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const AuctionReviewRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// خطوة "مراجعة المزاد": صورة السيارة المختارة + السعر الابتدائي + المدة
/// + إقرار الموافقة على الشروط.
class AuctionReviewStep extends StatelessWidget {
  final Map<String, dynamic>? selectedCar;
  final String startingPriceText;
  final String durationText;
  final String? errorMessage;

  const AuctionReviewStep({
    super.key,
    required this.selectedCar,
    required this.startingPriceText,
    required this.durationText,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final car = selectedCar ?? {};
    final imageUrl = AppConstants.resolveImageUrl(
      car['images'] is List && (car['images'] as List).isNotEmpty
          ? (car['images'] as List).first.toString()
          : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مراجعة المزاد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder:
                  (_, __) =>
                      Container(height: 170, color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '${car['make'] ?? ''} ${car['model'] ?? ''} ${car['year'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        AuctionReviewRow(
          label: 'السعر الابتدائي',
          value: '$startingPriceText ل.س',
        ),
        AuctionReviewRow(label: 'مدة المزاد', value: '$durationText ساعة'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'بإنشاء هذا المزاد، أنت توافق على شروط وأحكام المزادات.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        if (errorMessage != null) AuctionErrorText(message: errorMessage!),
      ],
    );
  }
}

/// شريط الأزرار السفلي (رجوع/متابعة أو إنشاء المزاد أو حفظ التعديلات).
class AuctionBottomBar extends StatelessWidget {
  final bool isSubmitting;
  final bool isLastStep;
  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const AuctionBottomBar({
    super.key,
    required this.isSubmitting,
    required this.isLastStep,
    required this.isEditing,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSubmitting ? null : onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('رجوع'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isSubmitting ? null : (isLastStep ? onSubmit : onNext),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child:
                  isSubmitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        isLastStep
                            ? (isEditing ? 'حفظ التعديلات' : 'إنشاء المزاد')
                            : 'متابعة',
                        style: const TextStyle(color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة سفلية (bottom sheet) تُعرض عند محاولة إنشاء مزاد دون اشتراك نشط.
class AuctionSubscriptionRequiredSheet extends StatelessWidget {
  final VoidCallback onSubscribeTap;

  const AuctionSubscriptionRequiredSheet({
    super.key,
    required this.onSubscribeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.gavel, color: Colors.white, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'يتطلب إنشاء مزاد اشتراكاً نشطاً',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'اشترك الآن حتى تتمكن من طرح سياراتك للمزايدة.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onSubscribeTap,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'اشترك الآن',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً'),
            ),
          ],
        ),
      ),
    );
  }
}
