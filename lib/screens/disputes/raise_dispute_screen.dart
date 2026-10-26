import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/dispute_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

/// رفع نزاع على معاملة فعلية (بيع/مزاد/تأجير) — بديل حقيقي لعدم وجود
/// آلية تصعيد للأدمن عند مشاكل مثل "السيارة مو متل الوصف" أو "ما رجّع
/// السيارة" أو "دفعت وما استلمت شي".
class RaiseDisputeScreen extends StatefulWidget {
  final int againstUserId;
  final String againstUserName;
  final String transactionType; // ad | auction | rental_booking
  final int transactionId;
  final String transactionTitle;

  const RaiseDisputeScreen({
    super.key,
    required this.againstUserId,
    required this.againstUserName,
    required this.transactionType,
    required this.transactionId,
    required this.transactionTitle,
  });

  @override
  State<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends State<RaiseDisputeScreen> {
  final DisputeService _disputeService = DisputeService();
  final TextEditingController _descriptionController = TextEditingController();
  String _category = 'item_not_as_described';
  bool _isSubmitting = false;

  static const _categories = {
    'payment_issue': 'مشكلة بالدفع',
    'item_not_as_described': 'السيارة/الخدمة مو متل الوصف',
    'no_delivery': 'لم يتم التسليم',
    'no_return': 'لم تُرجَع السيارة (تأجير)',
    'no_payment': 'لم يتم الدفع المتفق عليه',
    'damaged_item': 'ضرر بالسيارة',
    'other': 'أخرى',
  };

  Future<void> _submit() async {
    if (_descriptionController.text.trim().length < 10) {
      AppSnackbar.showError(context, title: 'اكتب وصفاً أوضح (10 أحرف على الأقل)');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _disputeService.raiseDispute(
        againstUserId: widget.againstUserId,
        transactionType: widget.transactionType,
        transactionId: widget.transactionId,
        category: _category,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        title: 'تم تسجيل النزاع',
        subtitle: 'سيتواصل فريق الدعم لمراجعته',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, title: 'تعذّر رفع النزاع', debugMessage: e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('الإبلاغ عن مشكلة', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.transactionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('ضد: ${widget.againstUserName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('نوع المشكلة', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._categories.entries.map(
              (entry) => RadioListTile<String>(
                value: entry.key,
                groupValue: _category,
                onChanged: (v) => setState(() => _category = v!),
                title: Text(entry.value),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            const Text('اشرح المشكلة بالتفصيل', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'اكتب هنا كل التفاصيل المهمة...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('إرسال النزاع', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
