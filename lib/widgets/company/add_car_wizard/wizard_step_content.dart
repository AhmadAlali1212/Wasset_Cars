import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'basic_info_step.dart';
import 'condition_description_step.dart';
import 'photos_video_step.dart';
import 'review_step.dart';

class WizardStepContent extends StatelessWidget {
  final int currentStep;
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

  const WizardStepContent({
    super.key,
    required this.currentStep,
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
  });

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 0:
        return CarBasicInfoStep(
          makeController: makeController,
          modelController: modelController,
          yearController: yearController,
          locationController: locationController,
          onPickLocation: onPickLocation,
        );
      case 1:
        return CarPhotosAndVideoStep(
          images: images,
          videos: videos,
          maxVideos: maxVideos,
          maxVideoSizeMb: maxVideoSizeMb,
          onPickImages: onPickImages,
          onPickVideo: onPickVideo,
          onRemoveVideo: onRemoveVideo,
        );
      case 2:
        return CarConditionAndDescriptionStep(
          condition: condition,
          onConditionChanged: onConditionChanged,
          descriptionController: descriptionController,
        );
      case 3:
        return CarReviewStep(
          make: makeController.text,
          model: modelController.text,
          year: yearController.text,
          location: locationController.text,
          latitude: latitude,
          longitude: longitude,
          condition: condition,
          description: descriptionController.text,
          imagesCount: images.length,
          videosCount: videos.length,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
