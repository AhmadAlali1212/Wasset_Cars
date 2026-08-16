import 'package:flutter/material.dart';
import 'package:mators_car/screens/home/payment_methods_screen.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/services/stripe_payment_helper.dart';

class IndividualWalletScreen extends StatefulWidget {
  const IndividualWalletScreen({super.key});

  @override
  State<IndividualWalletScreen> createState() => _IndividualWalletScreenState();
}

class _IndividualWalletScreenState extends State<IndividualWalletScreen> {
  final CompanyService _carService = CompanyService();
  late Future<Map<String, dynamic>> _walletFuture;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _walletFuture = _carService.getWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _refreshWallet() async {
    if (!mounted) return;
    setState(() {
      _walletFuture = _carService.getWallet();
    });
  }

  // تدفق شحن المحفظة الكامل عبر Stripe:
  // 1) ننشئ PaymentIntent من السيرفر (create-intent) ونحصل على client_secret
  // 2) نعرض ورقة الدفع الفعلية عبر flutter_stripe ليدخل المستخدم بيانات بطاقته
  // 3) بعد نجاح الدفع من طرف Stripe، السيرفر يستلم إشعار Webhook ويحدّث
  //    رصيد المحفظة تلقائياً — نستعلم عن حالة الطلب مرة أخيرة للتأكد ثم
  //    نحدّث عرض الرصيد بالشاشة.
  Future<void> _chargeWalletByMethod(
    String paymentMethod,
    double amount,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Map<String, dynamic> intent;
    try {
      intent = await _carService.createStripeTopupIntent(
        amountUsd: amount,
        requestId: StripePaymentHelper.generateRequestId(),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشل إنشاء عملية الشحن: ${e.toString()}')),
      );
      return;
    }

    final clientSecret = StripePaymentHelper.extractClientSecret(intent);
    final requestId = StripePaymentHelper.extractRequestId(intent);
    final serverPublishableKey = StripePaymentHelper.extractPublishableKey(
      intent,
    );

    if (clientSecret == null) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'لم يتم استلام بيانات الدفع من السيرفر (client_secret).',
          ),
        ),
      );
      return;
    }

    final result = await StripePaymentHelper.pay(
      clientSecret: clientSecret,
      serverPublishableKey: serverPublishableKey,
    );
    if (!mounted) return;

    switch (result.outcome) {
      case StripePaymentOutcome.canceled:
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('تم إلغاء عملية الدفع')),
        );
        return;
      case StripePaymentOutcome.failed:
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('فشلت عملية الدفع: ${result.message}')),
        );
        return;
      case StripePaymentOutcome.success:
        break;
    }

    // نستعلم عن حالة الطلب عدة مرات مع فاصل قصير، لأن تحديث الرصيد
    // الفعلي يحصل بعد وصول Stripe Webhook للسيرفر (وليس فور نجاح الدفع
    // بالجهاز مباشرة)، وقد يستغرق ذلك ثوانٍ قليلة.
    String? statusValue;
    if (requestId != null) {
      for (var attempt = 0; attempt < 6; attempt++) {
        try {
          final status = await _carService.getStripeTopupStatus(requestId);
          statusValue = StripePaymentHelper.extractTopupStatus(status);
        } catch (_) {
          // تجاهل فشل الاستعلام عن الحالة؛ الدفع نفسه نجح من طرف Stripe
        }
        if (statusValue == 'credited' || statusValue == 'failed') break;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    await _refreshWallet();
    if (!mounted) return;
    final creditedNow = statusValue == 'credited';
    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: Duration(seconds: creditedNow ? 4 : 8),
        content: Text(
          creditedNow
              ? 'تم شحن المحفظة بنجاح ✅'
              : 'تم الدفع بنجاح من طرف Stripe، لكن الرصيد لم يتحدّث بعد.\n'
                  'هذا يعني عادة أن Stripe Webhook لم يصل للسيرفر بعد '
                  '(بالتطوير المحلي تأكد أن أمر "stripe listen --forward-to '
                  '..." شغّال). اسحب الشاشة للأسفل لتحديث الرصيد لاحقاً.',
        ),
      ),
    );
  }

  Future<void> _showChargeDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('أدخل المبلغ'),
          content: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ بالدولار الأمريكي (USD)',
              hintText: 'مثال: 50',
              helperText: 'الحد الأقصى لكل عملية شحن: 10,000 USD',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final amount = double.tryParse(amountText);

                if (amount == null || amount <= 0) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('أدخل مبلغاً صحيحاً أكبر من صفر'),
                    ),
                  );
                  return;
                }

                if (amount > StripePaymentHelper.maxTopupAmountUsd) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'الحد الأقصى لعملية الشحن الواحدة هو 10,000 USD',
                      ),
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PaymentMethodsScreen(
                          amount: amount,
                          // بقيت طريقة دفع واحدة فقط (بطاقة ائتمان) بعد
                          // حذف "الرصيد الحالي" و"دفع عبر الهاتف" غير
                          // الفعلي، فلم تعد الحاجة لتفرّع الشرط هنا.
                          onMethodSelected: (_) async {
                            await _chargeWalletByMethod('sham_cash', amount);
                          },
                        ),
                  ),
                );
              },
              child: const Text('متابعة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWithdrawDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final destinationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('سحب الرصيد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  hintText: 'مثال: 50000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(
                  labelText: 'جهة الاستلام',
                  hintText: 'مثال: وكيل دمشق - رقم مرجعي 123',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final amount = double.tryParse(amountText);
                final destination = destinationController.text.trim();

                if (amount == null || amount <= 0) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('أدخل مبلغاً صحيحاً أكبر من صفر'),
                    ),
                  );
                  return;
                }

                if (destination.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('أدخل جهة استلام السحب')),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                try {
                  await _carService.withdrawWallet(
                    amount: amount,
                    withdrawalMethod: 'cash_agent',
                    destination: destination,
                  );
                  if (!mounted) return;
                  await _refreshWallet();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('تم إرسال طلب السحب بنجاح')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('فشل طلب السحب: ${e.toString()}')),
                  );
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('المحفظة الإلكترونية'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر جلب بيانات المحفظة\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final wallet = Map<String, dynamic>.from(snapshot.data ?? {});
          final walletData = wallet['wallet'];
          final balanceRaw =
              (walletData is Map ? walletData['available_balance'] : null) ??
              wallet['balance'] ??
              wallet['current_balance'] ??
              0;
          final balance = _formatAmount(balanceRaw);
          final currency = wallet['currency'] ?? 'ل.س';
          final transactions = _extractTransactions(wallet);

          return RefreshIndicator(
            onRefresh: _refreshWallet,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الرصيد الحالي',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$balance $currency',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showChargeDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F4C81),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('شحن المحفظة'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _showWithdrawDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('سحب الرصيد'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'آخر الحركات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (transactions.isEmpty)
                    const Center(child: Text('لا توجد حركات بعد'))
                  else
                    Column(
                      children:
                          transactions.take(10).map((transaction) {
                            final title =
                                transaction['title'] ??
                                transaction['description'] ??
                                'عملية';
                            final amount =
                                (transaction['amount'] ??
                                        transaction['value'] ??
                                        0)
                                    .toString();
                            final date =
                                transaction['date'] ??
                                transaction['created_at'] ??
                                'غير محدد';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    amount,
                                    style: TextStyle(
                                      color:
                                          amount.startsWith('-')
                                              ? Colors.red
                                              : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ينسّق أي رقم قادم من السيرفر (num/String) كعدد صحيح مقروء بفواصل آلاف.
  String _formatAmount(dynamic raw) {
    final value = raw is num ? raw : num.tryParse(raw?.toString() ?? '') ?? 0;
    final intPart = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return buffer.toString();
  }

  List<Map<String, dynamic>> _extractTransactions(Map<String, dynamic> wallet) {
    final rawTransactions = wallet['transactions'] ?? wallet['history'];
    // Laravel paginate() يُرجع كائناً { "data": [...], "current_page": ... }
    // وليس قائمة مباشرة، لذلك نتحقق من الشكلين.
    final list =
        rawTransactions is List
            ? rawTransactions
            : (rawTransactions is Map && rawTransactions['data'] is List)
            ? rawTransactions['data'] as List
            : null;
    if (list == null) return [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
