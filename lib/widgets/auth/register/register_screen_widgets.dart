import 'package:flutter/material.dart';

/// ودجات استُخرجت من شاشة إنشاء الحساب (register_screen.dart) دون أي
/// تغيير بالتصميم أو المنطق.

/// تسمية حقل موحّدة أعلى كل عنصر إدخال بالنموذج.
class RegisterFieldLabel extends StatelessWidget {
  final String text;
  const RegisterFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
    );
  }
}

/// تنبيه أصفر يظهر لحسابات الشركات فقط، يوضّح أن المستندات ستُراجَع قبل
/// تفعيل الحساب.
class DocumentReviewNotice extends StatelessWidget {
  const DocumentReviewNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'سيتم مراجعة مستنداتك من قبل الإدارة قبل تفعيل الحساب',
              style: TextStyle(color: Color(0xFFB45309), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// صف الموافقة على الشروط والأحكام (مربّع اختيار + نص + رابط قابل للنقر).
class TermsAgreementRow extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTapTerms;

  const TermsAgreementRow({super.key, required this.accepted, required this.onChanged, required this.onTapTerms});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: accepted, onChanged: onChanged, activeColor: const Color(0xFF051329)),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('أوافق على ', style: TextStyle(color: Color(0xFF4B5563))),
              GestureDetector(
                onTap: onTapTerms,
                child: const Text(
                  'الشروط والأحكام',
                  style: TextStyle(color: Color(0xFF0052CC), fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// السطر السفلي "لديك حساب بالفعل؟ تسجيل الدخول".
class LoginPromptRow extends StatelessWidget {
  final VoidCallback onTapLogin;
  const LoginPromptRow({super.key, required this.onTapLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('لديك حساب بالفعل؟ ', style: TextStyle(color: Color(0xFF6B7280))),
        TextButton(
          onPressed: onTapLogin,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFF0052CC),
          ),
          child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
