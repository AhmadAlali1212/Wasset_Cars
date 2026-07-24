import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/services/auth_serivces.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser ?? {};
    final name = user['name'] ?? 'اسم الشركة';
    final email = user['email'] ?? 'البريد الإلكتروني غير متوفر';
    final phone = user['phone_number'] ?? 'رقم الجوال غير متوفر';
    final accountType = user['account_type'] ?? 'company';

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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('نوع الحساب: $accountType'),
                  const SizedBox(height: 8),
                  Text('البريد الإلكتروني: $email'),
                  const SizedBox(height: 8),
                  Text('رقم الهاتف: $phone'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              title: 'إعدادات المعرض',
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
            _buildOptionCard(
              title: 'سجل المعاملات',
              icon: Icons.history,
              onTap: () {},
            ),
            _buildOptionCard(
              title: 'فريق الدعم',
              icon: Icons.support_agent_outlined,
              onTap: () {},
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
            color: Colors.black.withOpacity(0.04),
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
            color: color.withOpacity(0.12),
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
