import 'package:flutter/material.dart';

// نظام تنبيهات موحّد (Toast) بنفس تصميم البطاقة المطلوب: شريط ملوّن على
// الحافة + أيقونة بدائرة ملوّنة + عنوان وعنوان فرعي + رابط إجراء اختياري
// + زر إغلاق X. يُستخدم بدل SnackBar الافتراضي بكل أنحاء التطبيق.
//
// القاعدة المهمة: أي رسالة خطأ تُعرض هنا يجب أن تكون نصاً عربياً مختصراً
// وواضحاً للمستخدم (مثال: "تعذّر إتمام العملية")، وليست تفاصيل الاستثناء
// التقنية (مثل نص Exception/DioException الخام). تفاصيل الخطأ الكاملة
// تُطبع فقط بـ debugPrint لتظهر بـ Debug Console عند التطوير، ولا تصل
// إطلاقاً لواجهة المستخدم.
enum AppSnackbarType { success, info, warning, error }

class AppSnackbar {
  AppSnackbar._();

  static const _config = {
    AppSnackbarType.success: (
      color: Color(0xFF16A34A),
      bgTint: Color(0xFFEFFBF3),
      icon: Icons.check,
    ),
    AppSnackbarType.info: (
      color: Color(0xFF2563EB),
      bgTint: Color(0xFFEBF2FF),
      icon: Icons.info_outline,
    ),
    AppSnackbarType.warning: (
      color: Color(0xFFF59E0B),
      bgTint: Color(0xFFFFF7E8),
      icon: Icons.warning_amber_rounded,
    ),
    AppSnackbarType.error: (
      color: Color(0xFFDC2626),
      bgTint: Color(0xFFFDEDED),
      icon: Icons.close,
    ),
  };

  static void _show(
    BuildContext context, {
    required AppSnackbarType type,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? actionIcon,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    final cfg = _config[type]!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        content: _AppSnackbarCard(
          color: cfg.color,
          bgTint: cfg.bgTint,
          icon: cfg.icon,
          title: title,
          subtitle: subtitle,
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onAction: () {
            messenger.hideCurrentSnackBar();
            onAction?.call();
          },
          onDismiss: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    type: AppSnackbarType.success,
    title: title,
    subtitle: subtitle,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void showInfo(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    type: AppSnackbarType.info,
    title: title,
    subtitle: subtitle,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void showWarning(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    type: AppSnackbarType.warning,
    title: title,
    subtitle: subtitle,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  // ملاحظة: debugMessage يُطبع فقط بـ debugPrint (Debug Console)، ولا
  // يصل لواجهة المستخدم إطلاقاً. title/subtitle هما فقط ما يظهر للمستخدم.
  static void showError(
    BuildContext context, {
    String title = 'حدث خطأ',
    String? subtitle,
    Object? debugMessage,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (debugMessage != null) {
      debugPrint('AppSnackbar error: $debugMessage');
    }
    _show(
      context,
      type: AppSnackbarType.error,
      title: title,
      subtitle: subtitle ?? 'يرجى المحاولة مرة أخرى لاحقاً',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // تراجع/إلغاء (مثال: بعد الحذف)
  static void showUndo(
    BuildContext context, {
    required String title,
    String? subtitle,
    required VoidCallback onUndo,
  }) => _show(
    context,
    type: AppSnackbarType.error,
    title: title,
    subtitle: subtitle,
    actionLabel: 'تراجع',
    actionIcon: Icons.undo_rounded,
    onAction: onUndo,
  );
}

class _AppSnackbarCard extends StatelessWidget {
  final Color color;
  final Color bgTint;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _AppSnackbarCard({
    required this.color,
    required this.bgTint,
    required this.icon,
    required this.title,
    required this.onDismiss,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الشريط الملوّن على الحافة (يمين البطاقة بواجهة RTL)
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: bgTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: Colors.black87,
                                ),
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actionLabel != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: onAction,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (actionIcon != null) ...[
                                    Icon(actionIcon, size: 15, color: color),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    actionLabel!,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(width: 1, height: 22, color: Colors.grey.shade200),
                        ],
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onDismiss,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: bgTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 15, color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
