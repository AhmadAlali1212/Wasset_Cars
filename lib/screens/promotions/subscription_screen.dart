import 'package:flutter/material.dart';
import 'package:mators_car/services/subscription_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/screens/company/company_wallet_screen.dart';
import 'package:mators_car/screens/individual/individual_wallet_screen.dart';
import 'package:mators_car/ulits/colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  late Future<Map<String, dynamic>> _statusFuture;
  bool _isActing = false;
  String? _actionError;
  String? _accountType;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAccountType();
  }

  Future<void> _loadAccountType() async {
    final user = await AuthStorage.getUser();
    if (!mounted) return;
    setState(() => _accountType = user?['account_type']?.toString());
  }

  void _load() {
    _statusFuture = _subscriptionService.getSubscriptionStatus();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _statusFuture;
  }

  Future<void> _subscribe() async {
    setState(() {
      _isActing = true;
      _actionError = null;
    });
    try {
      await _subscriptionService.subscribe();
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الاشتراك بنجاح ✅'),
          backgroundColor: Colors.green,
        ),
      );
      // ننتظر لحظة قصيرة ليرى المستخدم شارة "نشط" قبل الرجوع تلقائياً
      // للشاشة التي طلبت الاشتراك (إنشاء مزاد/عرض ترويجي...).
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      // بعض الحالات: GET /subscription ما بيرجّع إشارة نشاط واضحة، لكن
      // محاولة الاشتراك نفسها بترفض بسبب وجود اشتراك نشط فعلاً. نتعامل
      // مع هذه الرسالة كتأكيد نجاح بدل عرضها كخطأ مخيف للمستخدم.
      if (message.contains('بالفعل نشط') ||
          message.contains('already active') ||
          message.contains('already subscribed')) {
        await _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أنت مشترك بالفعل ✅'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isActing = false);
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
      if (e is ApiException && e.isInsufficientBalance) {
        setState(() {
          _isActing = false;
          _actionError = 'رصيد محفظتك غير كافٍ لإتمام الاشتراك';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('رصيد محفظتك غير كافٍ لإتمام الاشتراك'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'شحن المحفظة',
              textColor: Colors.white,
              onPressed: _goToWallet,
            ),
          ),
        );
        return;
      }
      setState(() => _actionError = 'فشل الاشتراك: $e');
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  // يفتح شاشة المحفظة المناسبة (شركة/فرد) حسب نوع الحساب المخزّن محلياً
  Future<void> _goToWallet() async {
    final user = await AuthStorage.getUser();
    final accountType = user?['account_type']?.toString();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                accountType == 'company'
                    ? const CompanyWalletScreen()
                    : const IndividualWalletScreen(),
      ),
    );
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('إلغاء الاشتراك'),
            content: const Text('هل أنت متأكد من إلغاء اشتراكك الحالي؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تراجع'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'إلغاء الاشتراك',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() {
      _isActing = true;
      _actionError = null;
    });
    try {
      await _subscriptionService.cancelSubscription();
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionError = 'فشل إلغاء الاشتراك: $e');
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'الاشتراك',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _statusFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'تعذر جلب حالة الاشتراك\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data ?? {};
            final isActive = SubscriptionService.isActive(data);
            final endDate = SubscriptionService.endDate(data);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الباقة الأساسية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? Colors.green
                                      : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? 'نشط' : 'غير مفعّل',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isActive && endDate != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'ينتهي في $endDate',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (!isActive) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${SubscriptionService.priceFor(_accountType)} ل.س / شهرياً',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'مزايا الباقة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      _FeatureRow(text: 'نشر سيارات وإعلانات'),
                      _FeatureRow(text: 'إدارة السيارات'),
                      _FeatureRow(text: 'إنشاء عروض ترويجية'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_actionError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _actionError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child:
                      isActive
                          ? OutlinedButton(
                            onPressed: _isActing ? null : _cancel,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isActing
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'إلغاء الاشتراك',
                                      style: TextStyle(color: Colors.red),
                                    ),
                          )
                          : ElevatedButton(
                            onPressed: _isActing ? null : _subscribe,
                            style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isActing
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      'اشترك الآن',
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
