import 'package:flutter/material.dart';
import 'package:mators_car/screens/home/payment_methods_screen.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/services/stripe_payment_helper.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/company/wallet_widgets.dart';

class CompanyWalletScreen extends StatefulWidget {
  const CompanyWalletScreen({super.key});

  @override
  State<CompanyWalletScreen> createState() => _CompanyWalletScreenState();
}

class _CompanyWalletScreenState extends State<CompanyWalletScreen> {
  final CompanyService _companyService = CompanyService();
  late Future<Map<String, dynamic>> _walletFuture;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _walletFuture = _companyService.getWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _refreshWallet() async {
    if (!mounted) return;
    setState(() {
      _walletFuture = _companyService.getWallet();
    });
  }

  // تدفق شحن المحفظة الكامل عبر Stripe (نفس منطق شاشة محفظة الفرد)
  Future<void> _chargeWalletByMethod(
    String paymentMethod,
    double amount,
  ) async {
    Map<String, dynamic> intent;
    try {
      intent = await _companyService.createStripeTopupIntent(
        amountUsd: amount,
        requestId: StripePaymentHelper.generateRequestId(),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: context.tr('topup_start_failed'),
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
        title: context.tr('payment_start_failed'),
        subtitle: context.tr('payment_data_missing'),
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
        AppSnackbar.showInfo(context, title: context.tr('payment_cancelled'));
        return;
      case StripePaymentOutcome.failed:
        AppSnackbar.showError(
          context,
          title: context.tr('payment_failed'),
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
          final status = await _companyService.getStripeTopupStatus(requestId);
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
      AppSnackbar.showSuccess(
        context,
        title: context.tr('wallet_topup_success'),
      );
    } else {
      AppSnackbar.showInfo(
        context,
        title: context.tr('payment_pending_balance'),
        subtitle: context.tr('refresh_balance_later'),
      );
    }
  }

  Future<void> _showChargeDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('enter_amount')),
          content: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.tr('amount_usd'),
              hintText: context.tr('amount_example_50'),
              helperText: context.tr('topup_limit'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final amount = double.tryParse(amountText);

                if (amount == null || amount <= 0) {
                  AppSnackbar.showWarning(
                    context,
                    title: context.tr('valid_positive_amount'),
                  );
                  return;
                }

                if (amount > StripePaymentHelper.maxTopupAmountUsd) {
                  AppSnackbar.showWarning(
                    context,
                    title: context.tr('topup_limit_exceeded'),
                    subtitle: context.tr('topup_limit'),
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
              child: Text(context.tr('continue')),
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
          title: Text(context.tr('withdraw_balance')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.tr('amount'),
                  hintText: context.tr('amount_example_50000'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: context.tr('withdrawal_destination'),
                  hintText: context.tr('withdrawal_destination_example'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = _amountController.text.trim();
                final amount = double.tryParse(amountText);
                final destination = destinationController.text.trim();

                if (amount == null || amount <= 0) {
                  AppSnackbar.showWarning(
                    context,
                    title: context.tr('valid_positive_amount'),
                  );
                  return;
                }

                if (destination.isEmpty) {
                  AppSnackbar.showWarning(
                    context,
                    title: context.tr('enter_withdrawal_destination'),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                try {
                  await _companyService.withdrawWallet(
                    amount: amount,
                    withdrawalMethod: 'cash_agent',
                    destination: destination,
                  );
                  if (!mounted) return;
                  await _refreshWallet();
                  AppSnackbar.showSuccess(
                    context,
                    title: context.tr('withdrawal_request_sent'),
                  );
                } catch (e) {
                  if (!mounted) return;
                  AppSnackbar.showError(
                    context,
                    title: context.tr('withdrawal_request_failed'),
                    debugMessage: e,
                  );
                }
              },
              child: Text(context.tr('confirm')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('wallet')),
        centerTitle: true,
        elevation: 0,
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
          // رد WalletController@show يُرجع الرصيد متداخلاً هكذا:
          // { "wallet": { "available_balance": ..., "held_balance": ... } }
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
                  WalletBalanceCard(
                    balance: balance,
                    currency: currency,
                    onTopUp: _showChargeDialog,
                    onWithdraw: _showWithdrawDialog,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('recent_transactions'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  WalletTransactionsList(transactions: transactions),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ينسّق أي رقم قادم من السيرفر (num/String) كعدد صحيح مقروء بفواصل آلاف،
  // بدون أي مكتبة خارجية إضافية (بدل عرض "300000000.00" خاماً).
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
