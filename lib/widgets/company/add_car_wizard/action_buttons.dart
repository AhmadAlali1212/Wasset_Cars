import 'package:flutter/material.dart';

class WizardActionButtons extends StatelessWidget {
  final bool canGoBack;
  final VoidCallback? onBack;
  final bool isLastStep;
  final bool isSubmitting;
  final VoidCallback onNext;

  const WizardActionButtons({
    super.key,
    required this.canGoBack,
    required this.onBack,
    required this.isLastStep,
    required this.isSubmitting,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: canGoBack ? onBack : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F4C81),
              side: const BorderSide(color: Color(0xFF0F4C81)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('رجوع'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onNext,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF0F4C81),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child:
                isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLastStep ? 'إرسال' : 'متابعة'),
          ),
        ),
      ],
    );
  }
}
