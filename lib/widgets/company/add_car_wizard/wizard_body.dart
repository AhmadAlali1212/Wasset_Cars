import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'action_buttons.dart';
import 'wizard_header.dart';
import 'wizard_step_content.dart';

class WizardBody extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final GlobalKey<FormState> formKey;
  final TextEditingController makeController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final String condition;
  final List<XFile> images;
  final List<XFile> videos;
  final int maxVideos;
  final int maxVideoSizeMb;
  final double? latitude;
  final double? longitude;
  final VoidCallback onPickLocation;
  final VoidCallback onPickImages;
  final VoidCallback onPickVideo;
  final void Function(int index) onRemoveVideo;
  final ValueChanged<String?> onConditionChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const WizardBody({
    super.key,
    required this.currentStep,
    required this.isSubmitting,
    required this.formKey,
    required this.makeController,
    required this.modelController,
    required this.yearController,
    required this.descriptionController,
    required this.locationController,
    required this.condition,
    required this.images,
    required this.videos,
    required this.maxVideos,
    required this.maxVideoSizeMb,
    required this.latitude,
    required this.longitude,
    required this.onPickLocation,
    required this.onPickImages,
    required this.onPickVideo,
    required this.onRemoveVideo,
    required this.onConditionChanged,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          WizardStepperHeader(currentStep: currentStep),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: formKey,
              child: WizardStepContent(
                currentStep: currentStep,
                makeController: makeController,
                modelController: modelController,
                yearController: yearController,
                descriptionController: descriptionController,
                locationController: locationController,
                condition: condition,
                images: images,
                videos: videos,
                maxVideos: maxVideos,
                maxVideoSizeMb: maxVideoSizeMb,
                latitude: latitude,
                longitude: longitude,
                onPickLocation: onPickLocation,
                onPickImages: onPickImages,
                onPickVideo: onPickVideo,
                onRemoveVideo: onRemoveVideo,
                onConditionChanged: onConditionChanged,
              ),
            ),
          ),
          const SizedBox(height: 14),
          WizardActionButtons(
            canGoBack: currentStep != 0,
            onBack: onBack,
            isLastStep: currentStep == 3,
            isSubmitting: isSubmitting,
            onNext: currentStep == 3 ? onSubmit : onNext,
          ),
        ],
      ),
    );
  }
}
