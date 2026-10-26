import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/screens/company/map_location_picker_screen.dart';
import 'package:mators_car/services/controllers/ads_service.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/company/bulk_upload_widgets.dart';
import 'package:mators_car/widgets/company/add_car_wizard/add_car_wizard_widgets.dart';

/// شاشة "رفع السيارات الجماعي" الخاصة بحساب المعرض.
///
/// الفكرة: بدل تكرار معالج "إضافة سيارة" (Wizard) بكامل خطواته لكل سيارة
/// على حدة، يبني المعرض هنا "دفعة" (batch) من السيارات محلياً على الجهاز
/// أولاً (كل سيارة ببياناتها وصورها وسعرها)، ثم يرفعها كلها بضغطة واحدة.
///
/// كل عنصر في الدفعة يُرفع عبر نفس الـ Endpoints المستخدمة أصلاً في
/// [CompanyAddCarWizardScreen] لكل سيارة (POST /cars ثم POST /ads بالسعر)
/// حتى لا نعتمد على أي Endpoint غير مؤكد للرفع الجماعي الفعلي على السيرفر.
class CompanyBulkUploadScreen extends StatefulWidget {
  const CompanyBulkUploadScreen({super.key});

  @override
  State<CompanyBulkUploadScreen> createState() =>
      _CompanyBulkUploadScreenState();
}

class _CompanyBulkUploadScreenState extends State<CompanyBulkUploadScreen> {
  final CompanyService _companyService = CompanyService();
  final AdsService _adsService = AdsService();

  final List<BatchCarEntry> _batch = [];
  bool _isUploading = false;

  int get _successCount =>
      _batch.where((e) => e.status == BatchUploadStatus.success).length;

  Future<void> _openEntryForm({BatchCarEntry? existing, int? index}) async {
    final result = await Navigator.push<BatchCarEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => _BatchCarFormScreen(existing: existing),
      ),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _batch[index] = result;
      } else {
        _batch.add(result);
      }
    });
  }

  void _removeEntry(int index) {
    setState(() => _batch.removeAt(index));
  }

  Future<void> _uploadEntry(BatchCarEntry entry) async {
    setState(() {
      entry.status = BatchUploadStatus.uploading;
      entry.errorMessage = null;
    });

    try {
      final apiCondition = entry.condition == 'جديد' ? 'new' : 'used';
      final fields = {
        'make': entry.make.trim(),
        'model': entry.model.trim(),
        'year': int.tryParse(entry.year.trim()) ?? 0,
        'condition': apiCondition,
        'description': entry.description.trim(),
        'location': entry.location.trim(),
        if (entry.latitude != null)
          'latitude': entry.latitude!.toStringAsFixed(6),
        if (entry.longitude != null)
          'longitude': entry.longitude!.toStringAsFixed(6),
      };

      final carResponse = await _companyService.addCar(
        fields: fields,
        imageFiles: entry.images.map((x) => File(x.path)).toList(),
      );

      final carId = _extractCarId(carResponse);
      if (carId == null) {
        throw Exception('تعذر قراءة رقم السيارة بعد إنشائها');
      }

      final price = double.tryParse(entry.priceText.trim()) ?? 0;
      if (price > 0) {
        await _adsService.createAd(carId: carId, price: price);
      }

      setState(() => entry.status = BatchUploadStatus.success);
    } catch (e) {
      setState(() {
        entry.status = BatchUploadStatus.failed;
        entry.errorMessage = e.toString();
      });
    }
  }

  int? _extractCarId(Map<String, dynamic> response) {
    final direct = response['id'];
    if (direct is int) return direct;
    final nested = response['car'];
    if (nested is Map && nested['id'] is int) return nested['id'] as int;
    final data = response['data'];
    if (data is Map && data['id'] is int) return data['id'] as int;
    return null;
  }

  Future<void> _uploadAll() async {
    if (_batch.isEmpty) return;
    setState(() => _isUploading = true);
    for (final entry in _batch) {
      if (entry.status == BatchUploadStatus.success) continue;
      await _uploadEntry(entry);
    }
    setState(() => _isUploading = false);

    final failedCount =
        _batch.where((e) => e.status == BatchUploadStatus.failed).length;
    if (failedCount == 0) {
      AppSnackbar.showSuccess(
        context,
        title: '${context.tr('all_cars_uploaded')} ($_successCount)',
      );
    } else {
      AppSnackbar.showWarning(
        context,
        title:
            '${context.tr('cars_uploaded_failed')} $_successCount/$failedCount',
        subtitle: context.tr('retry_failed_items'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('bulk_upload_title')),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _batch.isEmpty
              ? const BulkUploadEmptyState()
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                itemCount: _batch.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = _batch[index];
                  return BulkUploadEntryCard(
                    entry: entry,
                    onEdit: () => _openEntryForm(existing: entry, index: index),
                    onDelete: () => _removeEntry(index),
                    onRetry: () => _uploadEntry(entry),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _openEntryForm(),
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add),
        label: Text(context.tr('add_car_to_batch')),
      ),
      bottomNavigationBar:
          _batch.isEmpty
              ? null
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadAll,
                    icon:
                        _isUploading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _isUploading
                          ? context.tr('uploading')
                          : '${context.tr('upload_all_cars')} (${_batch.length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF0F4C81),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}

/// نموذج إدخال/تعديل سيارة واحدة ضمن الدفعة — يعيد [BatchCarEntry] عند
/// الحفظ دون أي اتصال بالشبكة (الرفع الفعلي يحدث لاحقاً من الشاشة الرئيسية).
class _BatchCarFormScreen extends StatefulWidget {
  final BatchCarEntry? existing;

  const _BatchCarFormScreen({this.existing});

  @override
  State<_BatchCarFormScreen> createState() => _BatchCarFormScreenState();
}

class _BatchCarFormScreenState extends State<_BatchCarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxImages = 5;

  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;

  String _condition = 'مستعملة';
  double? _latitude;
  double? _longitude;
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _makeController = TextEditingController(text: e?.make ?? '');
    _modelController = TextEditingController(text: e?.model ?? '');
    _yearController = TextEditingController(text: e?.year ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _priceController = TextEditingController(text: e?.priceText ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _condition = e?.condition ?? 'مستعملة';
    _latitude = e?.latitude;
    _longitude = e?.longitude;
    _images = List<XFile>.from(e?.images ?? []);
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      AppSnackbar.showWarning(context, title: context.tr('max_five_images'));
      return;
    }
    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 70,
    );
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.take(remaining));
    });
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder:
            (_) => MapLocationPickerScreen(
              initialLatitude: _latitude,
              initialLongitude: _longitude,
            ),
      ),
    );
    if (result == null) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _locationController.text = result.address;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entry = widget.existing ?? BatchCarEntry();
    entry
      ..make = _makeController.text
      ..model = _modelController.text
      ..year = _yearController.text
      ..condition = _condition
      ..description = _descriptionController.text
      ..priceText = _priceController.text
      ..location = _locationController.text
      ..latitude = _latitude
      ..longitude = _longitude
      ..images = _images;
    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? context.tr('new_batch_car')
              : context.tr('edit_batch_car'),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            BatchImagesPicker(
              images: _images,
              onPickImages: _pickImages,
              onRemoveImage: (img) => setState(() => _images.remove(img)),
            ),
            const SizedBox(height: 16),
            WizardTextFormField(
              controller: _makeController,
              label: context.tr('make'),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? context.tr('required')
                          : null,
            ),
            WizardTextFormField(
              controller: _modelController,
              label: context.tr('model'),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? context.tr('required')
                          : null,
            ),
            WizardTextFormField(
              controller: _yearController,
              label: context.tr('manufacture_year'),
              keyboardType: TextInputType.number,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? context.tr('required')
                          : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DropdownButtonFormField<String>(
                initialValue: _condition,
                onChanged: (v) => setState(() => _condition = v!),
                decoration: InputDecoration(
                  labelText: context.tr('condition'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: context.adaptiveCardBg,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'جديد',
                    child: Text(context.tr('new')),
                  ),
                  DropdownMenuItem(
                    value: 'مستعملة',
                    child: Text(context.tr('used')),
                  ),
                ],
              ),
            ),
            WizardTextFormField(
              controller: _descriptionController,
              label: context.tr('description'),
              maxLines: 4,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? context.tr('required')
                          : null,
            ),
            WizardTextFormField(
              controller: _priceController,
              label: context.tr('optional_sale_price'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: _openMapPicker,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _locationController,
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? context.tr('select_location')
                                : null,
                    decoration: InputDecoration(
                      labelText: context.tr('location'),
                      suffixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF0F4C81),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('add_to_batch')),
          ),
        ),
      ),
    );
  }
}
