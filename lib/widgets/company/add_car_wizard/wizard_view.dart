import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'wizard_app_bar.dart';
import 'wizard_body.dart';

class CompanyAddCarWizardView extends StatelessWidget {
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

  const CompanyAddCarWizardView({
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
    return Scaffold(
      appBar: const WizardAppBar(),
      backgroundColor: const Color(0xFFF6F8FB),
      body: WizardBody(
        currentStep: currentStep,
        isSubmitting: isSubmitting,
        formKey: formKey,
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
        onBack: onBack,
        onNext: onNext,
        onSubmit: onSubmit,
      ),
    );
  }
}
