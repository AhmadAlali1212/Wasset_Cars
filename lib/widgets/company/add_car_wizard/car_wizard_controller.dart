import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/screens/company/map_location_picker_screen.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'location_editor_dialog.dart';
import 'location_options_sheet.dart';
import 'location_picker_sheet.dart';

class CarWizardController extends ChangeNotifier {
  static const int maxVideos = 2;
  static const int maxVideoSizeMb = 20;

  final CompanyService _companyService = CompanyService();
  final ImagePicker _imagePicker = ImagePicker();
  final int maxImages = 5;
  final formKey = GlobalKey<FormState>();
  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  int currentStep = 0;
  bool isSubmitting = false;
  String condition = 'مستعملة';
  final locations = <String>[];
  final images = <XFile>[];
  final videos = <XFile>[];
  double? latitude;
  double? longitude;

  Future<void> pickImages(BuildContext context) async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 70,
      );
      if (pickedFiles.isEmpty) return;

      if (images.length >= maxImages) {
        if (context.mounted) {
          AppSnackbar.showWarning(context, title: 'يمكنك إضافة 5 صور كحد أقصى');
        }
        return;
      }

      final filesToAdd = pickedFiles.take(maxImages - images.length).toList();
      if (filesToAdd.isEmpty) return;

      images.addAll(filesToAdd);
      notifyListeners();

      if (filesToAdd.length < pickedFiles.length && context.mounted) {
        AppSnackbar.showWarning(
          context,
          title: 'تمت إضافة الصور حتى الحد الأقصى',
          subtitle: 'الحد الأقصى 5 صور',
        );
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          title: 'تعذّر اختيار الصور',
          debugMessage: error,
        );
      }
    }
  }

  Future<void> pickVideo(BuildContext context) async {
    if (videos.length >= maxVideos) {
      AppSnackbar.showWarning(
        context,
        title: 'يمكنك إضافة $maxVideos فيديو كحد أقصى',
      );
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (pickedFile == null) return;

      final sizeInMb = await File(pickedFile.path).length() / (1024 * 1024);
      if (sizeInMb > maxVideoSizeMb) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            title: 'حجم الفيديو كبير جداً',
            subtitle: 'الحد الأقصى $maxVideoSizeMb ميغابايت لكل فيديو',
          );
        }
        return;
      }

      videos.add(pickedFile);
      notifyListeners();
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.showError(
          context,
          title: 'تعذّر اختيار الفيديو',
          debugMessage: error,
        );
      }
    }
  }

  void removeVideo(int index) {
    videos.removeAt(index);
    notifyListeners();
  }

  void selectCondition(String? value) {
    if (value == null) return;
    condition = value;
    notifyListeners();
  }

  void back() {
    if (currentStep == 0) return;
    currentStep -= 1;
    notifyListeners();
  }

  void next() {
    if (currentStep == 0 && !formKey.currentState!.validate()) return;
    currentStep += 1;
    notifyListeners();
  }

  void showLocationOptions(BuildContext context, String location) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => LocationOptionsSheet(
            location: location,
            onEdit: () {
              Navigator.pop(context);
              editLocation(context, location);
            },
            onDelete: () {
              locations.remove(location);
              if (locationController.text == location) {
                locationController.clear();
              }
              notifyListeners();
              Navigator.pop(context);
            },
          ),
    );
  }

  void addLocation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (_) => LocationEditorDialog(
            title: 'إضافة موقع جديد',
            initialValue: '',
            hintText: 'أدخل الموقع هنا',
            onSave: (value) {
              locations.add(value);
              locationController.text = value;
              notifyListeners();
            },
          ),
    );
  }

  void editLocation(BuildContext context, String location) {
    showDialog<void>(
      context: context,
      builder:
          (_) => LocationEditorDialog(
            title: 'تعديل الموقع',
            initialValue: location,
            hintText: 'أدخل الموقع الجديد',
            onSave: (value) {
              final index = locations.indexOf(location);
              if (index == -1) return;
              locations[index] = value;
              if (locationController.text == location) {
                locationController.text = value;
              }
              notifyListeners();
            },
          ),
    );
  }

  Future<void> openMapPicker(BuildContext context) async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder:
            (_) => MapLocationPickerScreen(
              initialLatitude: latitude,
              initialLongitude: longitude,
            ),
      ),
    );
    if (result == null || !context.mounted) return;

    latitude = result.latitude;
    longitude = result.longitude;
    locationController.text = result.address;
    if (!locations.contains(result.address)) locations.add(result.address);
    notifyListeners();
  }

  void openLocationPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => LocationPickerSheet(
            locations: locations,
            selectedLocation: locationController.text,
            onPickFromMap: () {
              Navigator.pop(context);
              openMapPicker(context);
            },
            onSelectLocation: (location) {
              locationController.text = location;
              notifyListeners();
              Navigator.pop(context);
            },
            onShowLocationOptions: (location) {
              Navigator.pop(context);
              showLocationOptions(context, location);
            },
            onAddLocation: () {
              Navigator.pop(context);
              addLocation(context);
            },
          ),
    );
  }

  Future<void> submitCar(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    if (latitude == null || longitude == null) {
      AppSnackbar.showWarning(
        context,
        title: 'الرجاء تحديد موقع السيارة على الخريطة',
      );
      return;
    }

    isSubmitting = true;
    notifyListeners();
    try {
      await _companyService.addCar(
        fields: {
          'make': makeController.text.trim(),
          'model': modelController.text.trim(),
          'year': int.tryParse(yearController.text.trim()) ?? 0,
          'condition': condition == 'جديد' ? 'new' : 'used',
          'description': descriptionController.text.trim(),
          'location': locationController.text.trim(),
          'latitude': latitude!.toStringAsFixed(6),
          'longitude': longitude!.toStringAsFixed(6),
        },
        imageFiles: images.map((item) => File(item.path)).toList(),
        videoFiles: videos.map((item) => File(item.path)).toList(),
      );

      if (!context.mounted) return;

      AppSnackbar.showSuccess(
        context,
        title: 'تم إرسال السيارة للمراجعة بنجاح',
      );
      Navigator.of(context).pop();
    } on DioException catch (error, stackTrace) {
      debugPrint('DioException while adding car: ${error.toString()}');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        _showErrorSnackBar(context, _formatSubmitError(error));
      }
    } catch (error, stackTrace) {
      debugPrint('Unexpected error while adding car: ${error.toString()}');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        _showErrorSnackBar(context, _formatSubmitError(error));
      }
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    AppSnackbar.showError(
      context,
      title: 'تعذّر إتمام العملية',
      subtitle: message,
    );
  }

  String _formatSubmitError(Object error) {
    if (error is DioException) {
      final responseMessage = _extractServerMessage(error.response?.data);
      if (responseMessage != null && responseMessage.isNotEmpty) {
        return responseMessage;
      }
      if (error.response?.statusCode != null) {
        return 'فشل إضافة السيارة (رمز الخطأ ${error.response!.statusCode}). يرجى مراجعة البيانات والمحاولة مرة أخرى.';
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return 'فشل إضافة السيارة: ${error.message}';
      }
    }
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      return message.startsWith('فشل') || message.startsWith('حدث')
          ? message
          : 'فشل إضافة السيارة: $message';
    }
    return 'حدث خطأ غير متوقع أثناء إضافة السيارة. يرجى المحاولة مرة أخرى.';
  }

  String? _extractServerMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final errors = map['errors'];
    final lines = <String>[];
    if (errors is Map && errors.isNotEmpty) {
      errors.forEach((key, value) {
        if (value is List) {
          final values = value.map((item) => item.toString()).join(', ');
          if (values.isNotEmpty) lines.add('$key: $values');
        } else if (value is String && value.trim().isNotEmpty) {
          lines.add('$key: ${value.trim()}');
        }
      });
    } else if (errors is String && errors.trim().isNotEmpty) {
      lines.add(errors.trim());
    }
    if (lines.isNotEmpty) return lines.join('\n');
    final message = map['message'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        : null;
  }

  @override
  void dispose() {
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
