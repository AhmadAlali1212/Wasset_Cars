import 'package:flutter/material.dart';

class WizardStepperHeader extends StatelessWidget {
  final int currentStep;
  static const List<String> stepLabels = [
    'معلومات السيارة',
    'صور السيارة',
    'المواصفات',
    'المراجعة',
  ];

  const WizardStepperHeader({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          stepLabels.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isActive = index == currentStep;
            final isDone = index < currentStep;

            return Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        isDone
                            ? const Color(0xFF0F4C81)
                            : isActive
                            ? const Color(0xFF334155)
                            : Colors.white,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isDone ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.black : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
