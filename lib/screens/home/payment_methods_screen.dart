// screens/payment/payment_methods_screen.dart
import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

// شاشة اختيار طريقة الدفع — تُستخدم حصراً لشحن المحفظة (top-up)، لذلك
// أُزيل خيار "الرصيد الحالي" لأنه غير منطقي هنا (لا يمكن الدفع من رصيد
// أنت بصدد شحنه أصلاً). كما أُزيل خيار "دفع عبر الهاتف" لأنه لم يكن
// فعلياً مفعّلاً: كلا الخيارين (بطاقة ائتمان / عبر الهاتف) كانا يفتحان
// بالضبط نفس Stripe PaymentSheet بلا أي فرق حقيقي، لأن SetupPaymentSheetParameters
// بـ StripePaymentHelper لا يمرّر applePay/googlePay إطلاقاً — فكان خيار
// "دفع عبر الهاتف" يعرض نفس نموذج إدخال البطاقة دون أي قيمة مضافة، ما
// يجعله مكرراً ومضللاً. الطريقة الوحيدة الفعلية المتبقية هي بطاقة الائتمان.
class PaymentMethodsScreen extends StatelessWidget {
  final double amount;
  final Function(String) onMethodSelected;

  const PaymentMethodsScreen({
    super.key,
    required this.amount,
    required this.onMethodSelected,
  });

  String get _formattedAmount {
    // نعرض رقماً عشرياً نظيفاً (مثال: 1000.0) دون تعقيد إضافي، بنفس
    // أسلوب عرض المبلغ بباقي شاشات المحفظة.
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(1)
        : amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'اختر طريقة الدفع',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المبلغ المطلوب:',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                Text(
                  '\$$_formattedAmount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اختر طريقة الدفع المناسبة',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PaymentMethodCard(
              icon: Icons.credit_card,
              title: 'بطاقة الائتمان',
              subtitle: 'ادفع باستخدام بطاقة ائتمان أو مدى',
              onTap: () {
                onMethodSelected('credit_card');
                Navigator.of(context).pop();
              },
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'جميع المعاملات آمنة ومشفرة',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEEF2)),
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
