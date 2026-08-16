import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/screens/company/map_location_picker_screen.dart';
import 'package:mators_car/services/ads_service.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/ulits/colors.dart';

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

/// حالة رفع عنصر واحد ضمن الدفعة.
enum _UploadStatus { pending, uploading, success, failed }

/// سيارة واحدة داخل الدفعة المحلية قبل الرفع.
class _BatchCarEntry {
  String make = '';
  String model = '';
  String year = '';
  String condition = 'مستعملة';
  String description = '';
  String priceText = '';
  String location = '';
  double? latitude;
  double? longitude;
  List<XFile> images = [];

  _UploadStatus status = _UploadStatus.pending;
  String? errorMessage;

  String get title {
    final t = '$make $model'.trim();
    return t.isEmpty ? 'سيارة جديدة' : t;
  }
}

class _CompanyBulkUploadScreenState extends State<CompanyBulkUploadScreen> {
  final CompanyService _companyService = CompanyService();
  final AdsService _adsService = AdsService();

  final List<_BatchCarEntry> _batch = [];
  bool _isUploading = false;

  int get _successCount =>
      _batch.where((e) => e.status == _UploadStatus.success).length;

  Future<void> _openEntryForm({_BatchCarEntry? existing, int? index}) async {
    final result = await Navigator.push<_BatchCarEntry>(
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

  Future<void> _uploadEntry(_BatchCarEntry entry) async {
    setState(() {
      entry.status = _UploadStatus.uploading;
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

      setState(() => entry.status = _UploadStatus.success);
    } catch (e) {
      setState(() {
        entry.status = _UploadStatus.failed;
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
      if (entry.status == _UploadStatus.success) continue;
      await _uploadEntry(entry);
    }

    if (!mounted) return;
    setState(() => _isUploading = false);

    final failedCount =
        _batch.where((e) => e.status == _UploadStatus.failed).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failedCount == 0
              ? 'تم رفع كل السيارات ($_successCount) بنجاح'
              : 'تم رفع $_successCount وفشل رفع $failedCount — يمكنك إعادة محاولة العناصر الفاشلة',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('رفع السيارات الجماعي'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          _batch.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                itemCount: _batch.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildEntryCard(index),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _openEntryForm(),
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add),
        label: const Text('إضافة سيارة للدفعة'),
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
                          ? 'جارِ الرفع...'
                          : 'رفع كل السيارات (${_batch.length})',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_filled_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'لم تضف أي سيارة بعد',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط "إضافة سيارة للدفعة" لبدء تجهيز عدة سيارات محلياً،\n'
              'ثم ارفعها جميعاً دفعة واحدة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(int index) {
    final entry = _batch[index];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                entry.images.isNotEmpty
                    ? Image.file(
                      File(entry.images.first.path),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.directions_car_outlined,
                        color: Colors.grey,
                      ),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.year.isNotEmpty
                      ? '${entry.year} • ${entry.condition}'
                      : entry.condition,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.priceText.trim().isNotEmpty
                      ? 'السعر: ${entry.priceText}'
                      : 'بدون سعر — ستُحفظ السيارة فقط',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                _buildStatusChip(entry),
              ],
            ),
          ),
          if (entry.status != _UploadStatus.uploading)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openEntryForm(existing: entry, index: index);
                } else if (value == 'delete') {
                  _removeEntry(index);
                } else if (value == 'retry') {
                  _uploadEntry(entry);
                }
              },
              itemBuilder:
                  (context) => [
                    if (entry.status != _UploadStatus.success)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('تعديل'),
                      ),
                    if (entry.status == _UploadStatus.failed)
                      const PopupMenuItem(
                        value: 'retry',
                        child: Text('إعادة المحاولة'),
                      ),
                    if (entry.status != _UploadStatus.success)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف'),
                      ),
                  ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(_BatchCarEntry entry) {
    late Color color;
    late String label;
    switch (entry.status) {
      case _UploadStatus.pending:
        color = Colors.grey;
        label = 'بانتظار الرفع';
        break;
      case _UploadStatus.uploading:
        color = AppColors.primary;
        label = 'جارِ الرفع...';
        break;
      case _UploadStatus.success:
        color = AppColors.success;
        label = 'تم الرفع بنجاح';
        break;
      case _UploadStatus.failed:
        color = AppColors.error;
        label = entry.errorMessage ?? 'فشل الرفع';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// نموذج إدخال/تعديل سيارة واحدة ضمن الدفعة — يعيد [_BatchCarEntry] عند
/// الحفظ دون أي اتصال بالشبكة (الرفع الفعلي يحدث لاحقاً من الشاشة الرئيسية).
class _BatchCarFormScreen extends StatefulWidget {
  final _BatchCarEntry? existing;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يمكنك إضافة 5 صور كحد أقصى')),
      );
      return;
    }
    final picked = await _imagePicker.pickMultiImage(imageQuality: 70);
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
    final entry = widget.existing ?? _BatchCarEntry();
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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(widget.existing == null ? 'سيارة جديدة للدفعة' : 'تعديل سيارة الدفعة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildImagesPicker(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _makeController,
              label: 'الماركة',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            _buildTextField(
              controller: _modelController,
              label: 'الموديل',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            _buildTextField(
              controller: _yearController,
              label: 'سنة الصنع',
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DropdownButtonFormField<String>(
                initialValue: _condition,
                onChanged: (v) => setState(() => _condition = v!),
                decoration: InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'جديد', child: Text('جديد')),
                  DropdownMenuItem(value: 'مستعملة', child: Text('مستعملة')),
                ],
              ),
            ),
            _buildTextField(
              controller: _descriptionController,
              label: 'الوصف',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            _buildTextField(
              controller: _priceController,
              label: 'سعر البيع (اختياري — اتركه فارغاً لحفظ السيارة بدون إعلان)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: _openMapPicker,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _locationController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء اختيار الموقع' : null,
                    decoration: InputDecoration(
                      labelText: 'الموقع',
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
            child: const Text('إضافة إلى الدفعة'),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesPicker() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey),
                color: AppColors.surfaceLight,
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
            ),
          ),
          ..._images.map(
            (img) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(img.path),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.remove(img)),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: AppColors.surface,
        ),
      ),
    );
  }
}
