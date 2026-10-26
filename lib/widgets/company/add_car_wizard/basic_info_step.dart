import 'package:flutter/material.dart';
import 'wizard_fields.dart';

class CarBasicInfoStep extends StatelessWidget {
  final TextEditingController makeController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController locationController;
  final VoidCallback onPickLocation;

  const CarBasicInfoStep({
    super.key,
    required this.makeController,
    required this.modelController,
    required this.yearController,
    required this.locationController,
    required this.onPickLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizardTextFormField(
            controller: makeController,
            label: 'الماركة',
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'الرجاء إدخال الماركة'
                        : null,
          ),
          WizardTextFormField(
            controller: modelController,
            label: 'الموديل',
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'الرجاء إدخال الموديل'
                        : null,
          ),
          WizardTextFormField(
            controller: yearController,
            label: 'سنة الصنع',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال سنة الصنع';
              }
              if (int.tryParse(value) == null) {
                return 'أدخل سنة صالحة';
              }
              return null;
            },
          ),
          WizardLocationField(
            controller: locationController,
            onTap: onPickLocation,
          ),
        ],
      ),
    );
  }
}
