import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/screens/address/address_screen.dart';
import 'package:mators_car/screens/individual/individual_inventory_screen.dart';
import 'package:mators_car/screens/individual/individual_wallet_screen.dart';
import 'package:mators_car/screens/settings/edit_profile_screen.dart';
import 'package:mators_car/screens/settings/settings_screen.dart';
import 'package:mators_car/services/controllers/auth_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

class IndividualProfileScreen extends StatelessWidget {
  const IndividualProfileScreen({super.key});

  // account_type يصل أحياناً كنص بسيط وأحياناً ككائن كامل لعلاقة "نوع
  // الحساب" ({id, name, description, ...})؛ طباعته مباشرة تُظهر نص الـ
  // Map الخام بالواجهة، لذلك نستخرج منه الاسم فقط عند الحاجة.
  String _accountTypeLabel(BuildContext context, dynamic raw) {
    String value = 'individual';
    if (raw is Map) {
      value = (raw['name'] ?? raw['type'] ?? 'individual').toString();
    } else if (raw != null) {
      value = raw.toString();
    }
    switch (value.trim().toLowerCase()) {
      case 'company':
        return context.tr('company');
      case 'individual':
        return context.tr('individual');
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser ?? {};
    final name = user['name'] ?? context.tr('user');
    final email = user['email'] ?? context.tr('email_unavailable');
    final phone = user['phone_number'] ?? context.tr('phone_unavailable');
    final accountType = _accountTypeLabel(context, user['account_type']);

    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('my_profile')),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: context.adaptiveCardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${context.tr('account_type')}: $accountType'),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: TextStyle(
                            color: context.adaptiveTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            color: context.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildMenuItem(
              context,
              icon: Icons.edit_outlined,
              title: context.tr('edit_profile'),
              subtitle: context.tr('edit_profile_subtitle'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.directions_car_outlined,
              title: context.tr('my_cars_ads'),
              subtitle: context.tr('inventory_subtitle'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IndividualInventoryScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: context.tr('wallet'),
              subtitle: context.tr('wallet_subtitle'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IndividualWalletScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: context.tr('my_addresses'),
              subtitle: context.tr('addresses_subtitle'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: context.tr('settings'),
              subtitle: context.tr('settings_subtitle'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout_outlined,
              title: context.tr('logout'),
              subtitle: context.tr('logout_subtitle'),
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(0xFF0F4C81),
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
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
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? context.adaptiveTextPrimary,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
