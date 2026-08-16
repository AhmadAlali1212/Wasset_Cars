import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// أداة موحّدة للاتصال (tel:) وفتح محادثة واتساب (wa.me) باستخدام رقم
// الهاتف الحقيقي الذي أدخله المستخدم (شركة أو فرد) عند إنشاء حسابه
// (phone_number)، بدل أي محاكاة أو شاشة وهمية.
class ContactLauncher {
  ContactLauncher._();

  // ينظّف الرقم من أي مسافات/رموز غير رقمية، ويضيف مفتاح سوريا +963
  // افتراضياً إذا كان الرقم محلياً (يبدأ بصفر) ولا يحمل مفتاح دولة أصلاً.
  static String _normalize(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('00')) digits = '+${digits.substring(2)}';
    if (digits.startsWith('0')) digits = '+963${digits.substring(1)}';
    if (!digits.startsWith('+')) digits = '+$digits';
    return digits;
  }

  static Future<void> call(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showMissingPhoneMessage(context);
      return;
    }
    final number = _normalize(phone);
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      _showLaunchFailedMessage(context, 'تطبيق الاتصال');
    }
  }

  static Future<void> whatsapp(
    BuildContext context,
    String? phone, {
    String message = '',
  }) async {
    if (phone == null || phone.trim().isEmpty) {
      _showMissingPhoneMessage(context);
      return;
    }
    // wa.me يتطلب الرقم بدون علامة + بالبداية
    final number = _normalize(phone).replaceFirst('+', '');
    final uri = Uri.parse(
      'https://wa.me/$number${message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showLaunchFailedMessage(context, 'واتساب');
    }
  }

  static void _showMissingPhoneMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يوجد رقم هاتف مسجّل لهذا المستخدم')),
    );
  }

  static void _showLaunchFailedMessage(BuildContext context, String target) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تعذر فتح $target على جهازك')));
  }
}
