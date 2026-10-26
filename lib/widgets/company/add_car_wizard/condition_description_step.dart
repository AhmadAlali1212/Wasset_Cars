import 'package:flutter/material.dart';
import 'wizard_fields.dart';

class CarConditionAndDescriptionStep extends StatelessWidget {
  final String condition;
  final ValueChanged<String?> onConditionChanged;
  final TextEditingController descriptionController;

  const CarConditionAndDescriptionStep({
    super.key,
    required this.condition,
    required this.onConditionChanged,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizardDropdownField(
            label: 'الحالة',
            value: condition,
            options: const ['جديد', 'مستعملة'],
            onChanged: onConditionChanged,
          ),
          const SizedBox(height: 14),
          WizardTextFormField(
            controller: descriptionController,
            label: 'الوصف',
            maxLines: 5,
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'الرجاء إدخال وصف للسيارة'
                        : null,
          ),
        ],
      ),
    );
  }
}
