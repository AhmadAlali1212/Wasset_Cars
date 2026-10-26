import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/screens/notifications/notifications_screen.dart';
import 'package:mators_car/screens/settings/blocked_users_screen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/changed_local.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ⬅️ جديد: الوضع الليلي واللغة كانا مبنيَين بالكامل بـ ChangedLocalProvider
    // (يحفظ الاختيار بـ SharedPreferences) لكن بلا أي واجهة تستخدمهما ولا
    // ربط بـ MaterialApp — كان بلا أي تأثير فعلي رغم اكتمال الكود اللازم له.
    final localeProvider = context.watch<ChangedLocalProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.adaptiveCardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEAF1FF),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('temporary_settings'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('settings_description'),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.adaptiveTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ⬅️ جديد: مفتاح الوضع الليلي الفعلي
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.adaptiveCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.adaptiveBorder),
            ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.dark_mode_outlined,
                color: AppColors.primary,
              ),
              title: Text(context.tr('dark_mode')),
              subtitle: Text(context.tr('dark_mode_subtitle')),
              value: localeProvider.isDarkMode,
              onChanged: (value) => localeProvider.changeThemeMode(value),
            ),
          ),
          // ⬅️ جديد: اختيار اللغة الفعلي (عربي/إنجليزي)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.adaptiveCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.adaptiveBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text(context.tr('language')),
              subtitle: Text(
                localeProvider.language?.languageCode == 'en'
                    ? context.tr('english')
                    : context.tr('arabic'),
              ),
              trailing: DropdownButton<String>(
                value: localeProvider.language?.languageCode ?? 'ar',
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(
                    value: 'ar',
                    child: Text(context.tr('arabic')),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(context.tr('english')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) localeProvider.changeLang(value);
                },
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.person_outline,
            title: context.tr('profile'),
            subtitle: context.tr('back_to_account'),
            onTap: () => Navigator.pop(context),
          ),
          _SettingsTile(
            icon: Icons.notifications_none,
            title: context.tr('notifications'),
            subtitle: context.tr('view_notifications'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.block,
            title: context.tr('blocked_users'),
            subtitle: context.tr('manage_blocked_users'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedUsersScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: context.tr('privacy_and_security'),
            subtitle: context.tr('coming_soon'),
            onTap: () {
              AppSnackbar.showInfo(
                context,
                title: context.tr('privacy_coming_soon'),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: context.tr('logout'),
            subtitle: context.tr('logout_from_profile'),
            onTap: () {
              AppSnackbar.showInfo(
                context,
                title: context.tr('logout_from_profile'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.adaptiveBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? () {},
      ),
    );
  }
}
