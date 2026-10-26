import 'package:flutter/material.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

/// ودجات استُخرجت من شاشة محفظة الشركة (company_wallet_screen.dart) دون
/// أي تغيير بالتصميم أو المنطق.

/// البطاقة الزرقاء العلوية: الرصيد الحالي + زرَّي شحن/سحب الرصيد.
class WalletBalanceCard extends StatelessWidget {
  final String balance;
  final String currency;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.currency,
    required this.onTopUp,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0F4C81), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('current_balance'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            '$balance $currency',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onTopUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F4C81),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(context.tr('top_up_wallet')),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onWithdraw,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(context.tr('withdraw_balance')),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// عنصر عملية مالية واحدة (عنوان + تاريخ + مبلغ ملوّن حسب الإشارة).
class WalletTransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;

  const WalletTransactionItem({super.key, required this.title, required this.amount, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(color: amount.startsWith('-') ? Colors.red : Colors.green, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// قائمة آخر 10 عمليات مالية، أو نص "لا توجد عمليات" إن كانت فارغة.
class WalletTransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const WalletTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(child: Text(context.tr('no_transactions')));
    }
    return Column(
      children:
          transactions.take(10).map((transaction) {
            final title = transaction['title'] ?? transaction['description'] ?? 'عملية';
            final amount = (transaction['amount'] ?? transaction['value'] ?? 0).toString();
            final date = transaction['date'] ?? transaction['created_at'] ?? 'غير محدد';
            return WalletTransactionItem(title: title, amount: amount, date: date);
          }).toList(),
    );
  }
}
