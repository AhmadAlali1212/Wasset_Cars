import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/screens/company/company_public_profile_screen.dart';
import 'package:mators_car/screens/company/company_wallet_screen.dart';
import 'package:mators_car/screens/promotions/promotions_list_screen.dart';
import 'package:mators_car/screens/promotions/subscription_screen.dart';
import 'package:mators_car/screens/settings/settings_screen.dart';
import 'package:mators_car/services/auth_serivces.dart';
import 'package:mators_car/services/subscription_service.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // null = جارِ التحقق، true/false = نتيجة معروفة. شارة التوثيق مرتبطة
  // مباشرة بوجود اشتراك نشط (وفق طلب المعرض): مشترك = موثّق.
  bool? _isSubscribed;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final status = await _subscriptionService.getSubscriptionStatus();
      final isActive = SubscriptionService.isActive(status);
      if (!mounted) return;
      setState(() => _isSubscribed = isActive);
    } catch (_) {
      if (!mounted) return;
      // في حال تعذّر التحقق (مثلاً لا يوجد اتصال) لا نظهر شارة توثيق
      // خاطئة، ونعامل الحالة كغير مشترك حتى يعاد التحقق لاحقاً.
      setState(() => _isSubscribed = false);
    }
  }

  Future<void> _goToSubscription() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
    // بعد العودة من شاشة الاشتراك أعد التحقق فوراً بدل انتظار الشاشة القادمة،
    // حتى تنعكس شارة التوثيق مباشرة إن اشترك للتو.
    _checkSubscription();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser ?? {};
    final name = user['name'] ?? 'اسم الشركة';
    final email = user['email'] ?? 'البريد الإلكتروني غير متوفر';
    final phone = user['phone_number'] ?? 'رقم الجوال غير متوفر';
    final accountType = _accountTypeLabel(user['account_type']);
    final followersRaw = user['followers_count'];
    final followersText = followersRaw != null ? followersRaw.toString() : '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('ملف المعرض'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              // الضغط على بطاقة معلومات الحساب ينقل إلى صفحة "البروفايل"
              // الكاملة (الشعار، الغلاف، التقييمات، عدد السيارات...) —
              // نفس الصفحة التي يراها الزوار، لكن بصفتها ملفك الخاص فتُخفى
              // منها أزرار المتابعة/التواصل تلقائياً.
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => CompanyPublicProfileScreen(company: user),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مرحبا بك في معرضك',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isSubscribed == true) ...[
                        const SizedBox(width: 6),
                        const Tooltip(
                          message: 'حساب موثّق (مشترك)',
                          child: Icon(
                            Icons.verified,
                            color: Color(0xFF0F4C81),
                            size: 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  // بطاقة عدد المتابعين
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$followersText متابع',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('نوع الحساب: $accountType'),
                  const SizedBox(height: 8),
                  Text('البريد الإلكتروني: $email'),
                  const SizedBox(height: 8),
                  Text('رقم الهاتف: $phone'),

                  // إن لم يكن الحساب مشتركاً (وبالتالي غير موثّق)، نعرض دعوة
                  // واضحة للاشتراك بدل ترك المستخدم يبحث عنها بنفسه.
                  if (_isSubscribed == false) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _goToSubscription,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4C81).withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              color: Color(0xFF0F4C81),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'وثّق حسابك عبر الاشتراك ليظهر لعملائك شارة '
                                'التوثيق ويكسبهم ثقة أكبر بمعرضك',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0F4C81),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Color(0xFF0F4C81),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              title: 'إعدادات المعرض',
              icon: Icons.settings_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _buildOptionCard(
              title: 'سجل المعاملات',
              icon: Icons.history,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyWalletScreen(),
                  ),
                );
              },
            ),
            _buildOptionCard(
              title: _isSubscribed == true ? 'الاشتراك (نشط ✓)' : 'الاشتراك',
              icon:
                  _isSubscribed == true
                      ? Icons.verified
                      : Icons.workspace_premium_outlined,
              onTap: _goToSubscription,
            ),
            _buildOptionCard(
              title: 'إدارة العروض الترويجية',
              icon: Icons.campaign_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PromotionsScreen(),
                  ),
                );
              },
            ),
            _buildOptionCard(
              title: 'فريق الدعم',
              icon: Icons.support_agent_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('للتواصل مع الدعم: support@matorscar.com'),
                  ),
                );
              },
            ),
            _buildOptionCard(
              title: 'تسجيل الخروج',
              icon: Icons.logout_outlined,
              color: Colors.red.shade600,
              textColor: Colors.red.shade700,
              onTap: () async {
                await authService.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // account_type يصل أحياناً كنص بسيط ('company') وأحياناً ككائن كامل
  // لعلاقة "نوع الحساب" ({id, name, description, ...})؛ طباعته مباشرة
  // بدون هذه الدالة هي سبب ظهور نص الـ Map الخام بالواجهة كما بالصورة.
  String _accountTypeLabel(dynamic raw) {
    String value = 'company';
    if (raw is Map) {
      value = (raw['name'] ?? raw['type'] ?? 'company').toString();
    } else if (raw != null) {
      value = raw.toString();
    }
    switch (value.trim().toLowerCase()) {
      case 'company':
        return 'معرض';
      case 'individual':
        return 'فرد';
      default:
        return value;
    }
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF0F4C81),
    Color textColor = Colors.black,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
