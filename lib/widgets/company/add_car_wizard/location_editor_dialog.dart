import 'package:flutter/material.dart';

class LocationEditorDialog extends StatelessWidget {
  final String title;
  final String initialValue;
  final String hintText;
  final ValueChanged<String> onSave;

  const LocationEditorDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hintText),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              onSave(value);
              Navigator.pop(context);
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
