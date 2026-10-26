import 'package:flutter/material.dart';

class ErrorDetailsDialog extends StatelessWidget {
  final String title;
  final String details;
  final VoidCallback onCopy;

  const ErrorDetailsDialog({
    super.key,
    required this.title,
    required this.details,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SelectableText(
          details.isNotEmpty ? details : 'لا توجد تفاصيل إضافية',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        TextButton(onPressed: onCopy, child: const Text('نسخ')),
      ],
    );
  }
}
