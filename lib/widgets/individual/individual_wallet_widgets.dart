import 'package:flutter/material.dart';

/// ودجات استُخرجت من شاشة محفظة الفرد (individual_wallet_screen.dart)
/// دون أي تغيير بالتصميم أو المنطق.

/// البطاقة الزرقاء العلوية: الرصيد الحالي + زرَّي شحن/سحب الرصيد.
class IndividualWalletBalanceCard extends StatelessWidget {
  final String balance;
  final String currency;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;

  const IndividualWalletBalanceCard({
    super.key,
    required this.balance,
    required this.currency,
    required this.onTopUp,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0F4C81), borderRadius: BorderRadius.circular(22)),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الرصيد الحالي', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Text(
            '$balance $currency',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onTopUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F4C81),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('شحن المحفظة'),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('سحب الرصيد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// عنصر حركة مالية واحدة (عنوان + تاريخ + مبلغ ملوّن حسب الإشارة).
class IndividualWalletTransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;

  const IndividualWalletTransactionItem({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: amount.startsWith('-') ? Colors.red : Colors.green)),
        ],
      ),
    );
  }
}

/// قائمة آخر 10 حركات، أو نص "لا توجد حركات بعد" إن كانت فارغة.
class IndividualWalletTransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const IndividualWalletTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('لا توجد حركات بعد'));
    }
    return Column(
      children:
          transactions.take(10).map((transaction) {
            final title = transaction['title'] ?? transaction['description'] ?? 'عملية';
            final amount = (transaction['amount'] ?? transaction['value'] ?? 0).toString();
            final date = transaction['date'] ?? transaction['created_at'] ?? 'غير محدد';
            return IndividualWalletTransactionItem(title: title, amount: amount, date: date);
          }).toList(),
    );
  }
}
