import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

/// ودجات استُخرجت من دوال _build... الخاصة بشاشة إضافة عرض ترويجي
/// (add_promotion_screen.dart) دون أي تغيير بالتصميم أو المنطق.

/// شريط تنبيه أعلى الشاشة يوضّح أن نشر عرض ترويجي يتطلب اشتراكاً نشطاً.
class PromotionSubscriptionBanner extends StatelessWidget {
  final VoidCallback onSubscribeTap;
  const PromotionSubscriptionBanner({super.key, required this.onSubscribeTap});

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
              'يتطلب نشر عرض ترويجي اشتراكاً نشطاً',
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

/// مؤشر خطوات المعالج (نقاط مرقّمة موصولة بخط) — خطوتان: معلومات أساسية،
/// ثم مراجعة ونشر.
class PromotionStepper extends StatelessWidget {
  final int step;
  static const List<String> stepTitles = ['معلومات أساسية', 'مراجعة ونشر'];

  const PromotionStepper({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(stepTitles.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < step;
            return Container(
              width: 40,
              height: 2,
              color: leftDone ? AppColors.primary : Colors.grey.shade300,
            );
          }
          final index = i ~/ 2;
          final isDone = index < step;
          final isCurrent = index == step;
          return Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDone || isCurrent ? AppColors.primary : Colors.grey.shade300,
                child:
                    isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${index + 1}', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// تسمية حقل موحّدة أعلى كل عنصر إدخال بالنموذج.
class PromotionFieldLabel extends StatelessWidget {
  final String text;
  const PromotionFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

/// حقل نص عام بنمط النموذج الموحّد.
class PromotionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final VoidCallback onChanged;

  const PromotionTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}

/// صندوق اختيار تاريخ (نص التاريخ + أيقونة تقويم).
class PromotionDateBox extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  final String Function(DateTime?) formatDate;

  const PromotionDateBox({
    super.key,
    required this.date,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatDate(date),
              style: TextStyle(fontSize: 13, color: date == null ? Colors.grey.shade400 : Colors.black),
            ),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// خطوة "المعلومات الأساسية": العنوان، الوصف، نوع العرض، القيمة، الكمية،
/// وتاريخ البداية والنهاية.
class PromotionBasicInfoStep extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String type;
  final ValueChanged<String?> onTypeChanged;
  final TextEditingController valueController;
  final TextEditingController quantityController;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final String Function(DateTime?) formatDate;
  final VoidCallback onFieldChanged;

  const PromotionBasicInfoStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.type,
    required this.onTypeChanged,
    required this.valueController,
    required this.quantityController,
    required this.startDate,
    required this.endDate,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.formatDate,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المعلومات الأساسية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const PromotionFieldLabel('عنوان العرض'),
        PromotionTextField(controller: titleController, hint: 'مثال: خصم الصيف', onChanged: onFieldChanged),
        const SizedBox(height: 14),
        const PromotionFieldLabel('وصف العرض'),
        PromotionTextField(
          controller: descriptionController,
          hint: 'وصف مختصر عن العرض',
          maxLines: 3,
          onChanged: onFieldChanged,
        ),
        const SizedBox(height: 14),
        const PromotionFieldLabel('نوع العرض'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: type,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              items: const [
                DropdownMenuItem(value: 'discount', child: Text('خصم (%)')),
                DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
              ],
              onChanged: onTypeChanged,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PromotionFieldLabel(type == 'discount' ? 'قيمة الخصم (%)' : 'القيمة'),
                  PromotionTextField(
                    controller: valueController,
                    hint: type == 'discount' ? '20' : '100000',
                    keyboardType: TextInputType.number,
                    onChanged: onFieldChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PromotionFieldLabel('الكمية'),
                  PromotionTextField(
                    controller: quantityController,
                    hint: '100',
                    keyboardType: TextInputType.number,
                    onChanged: onFieldChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PromotionFieldLabel('تاريخ البداية'),
                  PromotionDateBox(date: startDate, onTap: onPickStartDate, formatDate: formatDate),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PromotionFieldLabel('تاريخ النهاية'),
                  PromotionDateBox(date: endDate, onTap: onPickEndDate, formatDate: formatDate),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// صف واحد بخطوة المراجعة (تسمية + قيمة).
class PromotionReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const PromotionReviewRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// خطوة "مراجعة ونشر": بطاقة ملخّص العرض + بيانات إضافية + تنويه المراجعة.
class PromotionReviewStep extends StatelessWidget {
  final String title;
  final String type;
  final String value;
  final DateTime? startDate;
  final DateTime? endDate;
  final String Function(DateTime?) formatDate;
  final String quantity;
  final String description;
  final String? errorMessage;

  const PromotionReviewStep({
    super.key,
    required this.title,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.formatDate,
    required this.quantity,
    required this.description,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
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
            children: [
              Text(
                title.isEmpty ? 'عنوان العرض' : title,
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                type == 'discount' ? 'خصم $value%' : value,
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '${formatDate(startDate)}  →  ${formatDate(endDate)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PromotionReviewRow(label: 'الكمية', value: quantity),
        PromotionReviewRow(label: 'الوصف', value: description.isEmpty ? '—' : description),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.directions_car_filled, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'سيشمل هذا العرض تلقائياً جميع سياراتك المعروضة للبيع، '
                  'وستظهر كلها في قسم "العروض الترويجية" بمجرد اعتماد العرض.',
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        const Text(
          'سيخضع العرض لمراجعة الإدارة قبل نشره للعموم.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

/// شريط الأزرار السفلي (رجوع/متابعة أو نشر).
class PromotionBottomBar extends StatelessWidget {
  final int step;
  final bool isSubmitting;
  final bool basicInfoValid;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSubmit;

  const PromotionBottomBar({
    super.key,
    required this.step,
    required this.isSubmitting,
    required this.basicInfoValid,
    required this.onBack,
    required this.onContinue,
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
          if (step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('رجوع'),
              ),
            ),
          if (step > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  isSubmitting
                      ? null
                      : step == 0
                      ? (basicInfoValid ? onContinue : null)
                      : onSubmit,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  isSubmitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                      : Text(step == 0 ? 'متابعة' : 'نشر العرض', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

/// صف مزية واحدة داخل بطاقة "يتطلب اشتراكاً" (أيقونة صح + نص).
class SubscriptionFeatureRow extends StatelessWidget {
  final String text;
  const SubscriptionFeatureRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// بطاقة سفلية (bottom sheet) تظهر عندما يحاول المستخدم نشر عرض ترويجي
/// دون اشتراك نشط، وتقوده مباشرة لشاشة الاشتراك الحقيقية.
class SubscriptionRequiredSheet extends StatelessWidget {
  final VoidCallback onSubscribeTap;

  const SubscriptionRequiredSheet({super.key, required this.onSubscribeTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
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
                  Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'يتطلب نشر العروض الترويجية اشتراكاً نشطاً',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'اشترك الآن للاستفادة من نشر عروضك الترويجية وإدارتها.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SubscriptionFeatureRow(text: 'نشر عروض ترويجية غير محدودة'),
            const SubscriptionFeatureRow(text: 'ظهور العروض للمستخدمين مباشرة'),
            const SubscriptionFeatureRow(text: 'متابعة إحصائيات كل عرض'),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onSubscribeTap,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('اشترك الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('لاحقاً')),
          ],
        ),
      ),
    );
  }
}
