import 'package:flutter/material.dart';
import 'car_wizard_controller.dart';
import 'wizard_view.dart';

class CompanyAddCarWizardWidget extends StatefulWidget {
  const CompanyAddCarWizardWidget({super.key});

  @override
  State<CompanyAddCarWizardWidget> createState() =>
      _CompanyAddCarWizardWidgetState();
}

class _CompanyAddCarWizardWidgetState extends State<CompanyAddCarWizardWidget> {
  late final CarWizardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CarWizardController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return CompanyAddCarWizardView(
          currentStep: _controller.currentStep,
          isSubmitting: _controller.isSubmitting,
          formKey: _controller.formKey,
          makeController: _controller.makeController,
          modelController: _controller.modelController,
          yearController: _controller.yearController,
          descriptionController: _controller.descriptionController,
          locationController: _controller.locationController,
          condition: _controller.condition,
          images: _controller.images,
          videos: _controller.videos,
          maxVideos: CarWizardController.maxVideos,
          maxVideoSizeMb: CarWizardController.maxVideoSizeMb,
          latitude: _controller.latitude,
          longitude: _controller.longitude,
          onPickLocation: () => _controller.openLocationPicker(context),
          onPickImages: () => _controller.pickImages(context),
          onPickVideo: () => _controller.pickVideo(context),
          onRemoveVideo: _controller.removeVideo,
          onConditionChanged: _controller.selectCondition,
          onBack: _controller.back,
          onNext: _controller.next,
          onSubmit: () => _controller.submitCar(context),
        );
      },
    );
  }
}
