import 'package:flutter/material.dart';
import 'package:mators_car/screens/home/payment_methods_screen.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/services/stripe_payment_helper.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/individual/individual_wallet_widgets.dart';

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
    Map<String, dynamic> intent;
    try {
      intent = await _carService.createStripeTopupIntent(
        amountUsd: amount,
        requestId: StripePaymentHelper.generateRequestId(),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر بدء عملية الشحن',
        debugMessage: e,
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
      AppSnackbar.showError(
        context,
        title: 'تعذّر بدء عملية الدفع',
        subtitle: 'لم يتم استلام بيانات الدفع من السيرفر',
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
        AppSnackbar.showInfo(context, title: 'تم إلغاء عملية الدفع');
        return;
      case StripePaymentOutcome.failed:
        AppSnackbar.showError(
          context,
          title: 'فشلت عملية الدفع',
          subtitle: result.message,
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
    if (creditedNow) {
      AppSnackbar.showSuccess(context, title: 'تم شحن المحفظة بنجاح');
    } else {
      AppSnackbar.showInfo(
        context,
        title: 'تم الدفع، بانتظار تأكيد الرصيد',
        subtitle: 'اسحب الشاشة للأسفل لتحديث الرصيد بعد قليل',
      );
    }
  }

  Future<void> _showChargeDialog() async {
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
                  AppSnackbar.showWarning(
                    context,
                    title: 'أدخل مبلغاً صحيحاً أكبر من صفر',
                  );
                  return;
                }

                if (amount > StripePaymentHelper.maxTopupAmountUsd) {
                  AppSnackbar.showWarning(
                    context,
                    title: 'تجاوزت الحد الأقصى',
                    subtitle: 'الحد الأقصى لعملية الشحن الواحدة هو 10,000 USD',
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
                  AppSnackbar.showWarning(
                    context,
                    title: 'أدخل مبلغاً صحيحاً أكبر من صفر',
                  );
                  return;
                }

                if (destination.isEmpty) {
                  AppSnackbar.showWarning(
                    context,
                    title: 'أدخل جهة استلام السحب',
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
                  AppSnackbar.showSuccess(
                    context,
                    title: 'تم إرسال طلب السحب بنجاح',
                  );
                } catch (e) {
                  if (!mounted) return;
                  AppSnackbar.showError(
                    context,
                    title: 'تعذّر إرسال طلب السحب',
                    debugMessage: e,
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
                'تعذر جلب بيانات المحفظة\n'
                '${ApiException.userMessage(snapshot.error)}',
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
                  IndividualWalletBalanceCard(
                    balance: balance,
                    currency: currency,
                    onTopUp: _showChargeDialog,
                    onWithdraw: _showWithdrawDialog,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'آخر الحركات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  IndividualWalletTransactionsList(transactions: transactions),
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
