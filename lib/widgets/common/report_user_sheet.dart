import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/report_service.dart';
import 'package:mators_car/services/controllers/block_service.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

/// نافذة "إبلاغ عن مستخدم" قابلة لإعادة الاستخدام من أي شاشة (محادثة،
/// بروفايل شركة، تفاصيل إعلان...). ندمج زر "حظر أيضاً" بنفس النافذة
/// لأن أغلب حالات الإبلاغ الحقيقية (احتيال/إساءة) يريد المستخدم فيها
/// قطع التواصل فوراً كمان.
class ReportUserSheet {
  static Future<void> show(
    BuildContext context, {
    required int reportedUserId,
    String? contextType,
    int? contextId,
  }) async {
    String reason = 'fraud';
    final detailsController = TextEditingController();
    bool alsoBlock = true;

    const reasons = {
      'fraud': 'احتيال',
      'abuse': 'إساءة/تحرش',
      'inappropriate_content': 'محتوى غير لائق',
      'spam': 'سبام/إزعاج',
      'other': 'أخرى',
    };

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'الإبلاغ عن مستخدم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reasons.entries.map(
                      (entry) => RadioListTile<String>(
                        value: entry.key,
                        groupValue: reason,
                        onChanged: (v) => setState(() => reason = v!),
                        title: Text(entry.value),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'تفاصيل إضافية (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: alsoBlock,
                      onChanged: (v) => setState(() => alsoBlock = v ?? true),
                      title: const Text('حظر هذا المستخدم أيضاً'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'إرسال البلاغ',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ReportService().report(
        reportedUserId: reportedUserId,
        reason: reason,
        details: detailsController.text,
        contextType: contextType,
        contextId: contextId,
      );
      if (alsoBlock) {
        await BlockService().block(reportedUserId);
      }
      if (!context.mounted) return;
      AppSnackbar.showSuccess(
        context,
        title: alsoBlock ? 'تم إرسال البلاغ وحظر المستخدم' : 'تم إرسال البلاغ',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر إتمام العملية',
        debugMessage: e,
      );
    }
  }
}
