// screens/payment/payment_methods_screen.dart
import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

class PaymentMethodsScreen extends StatelessWidget {
  final double amount;
  final Function(String) onMethodSelected;

  const PaymentMethodsScreen({
    super.key,
    required this.amount,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر طريقة الدفع'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المبلغ المطلوب:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$amount ل.س',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PaymentMethodCard(
                  icon: Icons.account_balance_wallet,
                  title: 'الرصيد الحالي',
                  onTap: () => onMethodSelected('wallet'),
                ),
                const SizedBox(height: 16),
                PaymentMethodCard(
                  icon: Icons.credit_card,
                  title: 'بطاقة ائتمان',
                  onTap: () => onMethodSelected('credit_card'),
                ),
                const SizedBox(height: 16),
                PaymentMethodCard(
                  icon: Icons.mobile_friendly,
                  title: 'دفع عبر الهاتف',
                  onTap: () => onMethodSelected('mobile'),
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
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}