import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/ulits/constans.dart';
import 'package:mators_car/widgets/company/edit_car_widgets.dart';

class EditCarScreen extends StatefulWidget {
  final int carId;
  final Map<String, dynamic> car;

  const EditCarScreen({super.key, required this.carId, required this.car});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  static const Color _primaryBlue = Color(0xFF14245C);

  final CompanyService _companyService = CompanyService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _descriptionController;

  late String _condition; // 'new' | 'used'
  bool _isSaving = false;
  bool _isDeleting = false;

  String? _primaryImageUrl;

  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _newImages = [];
  static const int _maxImages = 5;

  // ⬅️ جديد: إدارة فيديوهات السيارة — عرض الموجودة، حذفها، وإضافة جديدة
  // (بأقصى 2 فيديو إجمالاً)، مباشرة عبر /cars/{id}/videos بدل انتظار حفظ
  // بقية التعديلات، حتى لا يفقد المستخدم صوره/بياناته المُعدَّلة لو فشل
  // رفع الفيديو لأي سبب.
  List<String> _existingVideos = [];
  static const int _maxVideos = 2;
  static const int _maxVideoSizeMb = 20;
  bool _isUploadingVideo = false;
  String? _removingVideoUrl;

  @override
  void initState() {
    super.initState();
    final car = widget.car;

    _makeController = TextEditingController(
      text: (car['make'] ?? car['name'] ?? '').toString(),
    );
    _modelController = TextEditingController(
      text: (car['model'] ?? '').toString(),
    );
    _yearController = TextEditingController(
      text: (car['year'] ?? '').toString(),
    );
    _descriptionController = TextEditingController(
      text: (car['description'] ?? '').toString(),
    );
    _condition = (car['condition'] ?? 'used').toString();
    _primaryImageUrl = _getPrimaryImage(car['images'] ?? car['image']);

    // ⬅️ جديد: تحميل الفيديوهات الحالية للسيارة (إن وُجدت)
    final videosData = car['videos'];
    if (videosData is List) {
      _existingVideos =
          videosData
              .map((item) {
                if (item is String) return item;
                if (item is Map) {
                  return (item['url'] ?? item['video_path'] ?? '').toString();
                }
                return '';
              })
              .where((url) => url.isNotEmpty)
              .toList();
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _getPrimaryImage(dynamic imagesData) {
    String? raw;
    if (imagesData is List && imagesData.isNotEmpty) {
      final firstItem = imagesData.first;
      if (firstItem is String) raw = firstItem;
      if (firstItem is Map && firstItem['url'] != null)
        raw = firstItem['url'].toString();
      if (firstItem is Map && firstItem['image_path'] != null) {
        raw = firstItem['image_path'].toString();
      }
    } else if (imagesData is String && imagesData.isNotEmpty) {
      raw = imagesData;
    }
    return AppConstants.resolveImageUrl(raw);
  }

  // يختار صوراً جديدة لاستبدال صور السيارة الحالية. حسب توثيق الـ API:
  // تعديل الصور يتطلب multipart/form-data (مختلف عن التعديل النصي العادي).
  Future<void> _pickImages() async {
    if (_newImages.length >= _maxImages) {
      AppSnackbar.showWarning(context, title: 'الحد الأقصى $_maxImages صور');
      return;
    }
    try {
      final remainingSlots = _maxImages - _newImages.length;
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked.isEmpty) return;
      final filesToAdd = picked.take(remainingSlots).toList();
      setState(() => _newImages.addAll(filesToAdd));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر اختيار الصور',
        debugMessage: e,
      );
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  // حفظ التعديلات عبر PUT /cars/{car_id} (بدون صور، حسب الـ Collection)
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final fields = <String, dynamic>{
      'make': _makeController.text.trim(),
      'model': _modelController.text.trim(),
      'year':
          int.tryParse(_yearController.text.trim()) ??
          _yearController.text.trim(),
      'condition': _condition,
      'description': _descriptionController.text.trim(),
    };

    // نحافظ على الإحداثيات الأصلية إن وُجدت لأن الـ endpoint يقبلها ضمن نفس الطلب
    if (widget.car['latitude'] != null)
      fields['latitude'] = widget.car['latitude'];
    if (widget.car['longitude'] != null)
      fields['longitude'] = widget.car['longitude'];

    try {
      await _companyService.updateCar(
        carId: widget.carId,
        fields: fields,
        newImageFiles:
            _newImages.isEmpty
                ? null
                : _newImages.map((x) => File(x.path)).toList(),
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تم حفظ التعديلات بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حفظ التعديلات',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // حذف السيارة عبر DELETE /cars/{car_id}
  Future<void> _deleteCar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('حذف السيارة'),
            content: const Text(
              'هل أنت متأكد من حذف هذه السيارة؟ لا يمكن التراجع عن هذا الإجراء.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _companyService.deleteCar(widget.carId);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تم حذف السيارة بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حذف السيارة',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _buildImagesEditor() => EditCarImagesEditor(
    newImages: _newImages,
    maxImages: _maxImages,
    primaryImageUrl: _primaryImageUrl,
    onPickImages: _pickImages,
    onRemoveNewImage: _removeNewImage,
    accentColor: _primaryBlue,
  );

  // ⬅️ جديد: اختيار ورفع فيديو جديد فوراً (endpoint مستقل عن حفظ النموذج)
  Future<void> _pickAndUploadVideo() async {
    if (_existingVideos.length >= _maxVideos) {
      AppSnackbar.showWarning(
        context,
        title: 'يمكنك إضافة $_maxVideos فيديو كحد أقصى لكل سيارة',
      );
      return;
    }

    final pickedFile = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (pickedFile == null) return;

    final sizeInMb = await File(pickedFile.path).length() / (1024 * 1024);
    if (sizeInMb > _maxVideoSizeMb) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'حجم الفيديو كبير جداً',
        subtitle: 'الحد الأقصى $_maxVideoSizeMb ميغابايت لكل فيديو',
      );
      return;
    }

    setState(() => _isUploadingVideo = true);
    try {
      final updatedVideos = await _companyService.addCarVideos(
        carId: widget.carId,
        videoFiles: [File(pickedFile.path)],
      );
      if (!mounted) return;
      setState(() => _existingVideos = updatedVideos);
      AppSnackbar.showSuccess(context, title: 'تم رفع الفيديو بنجاح');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر رفع الفيديو',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isUploadingVideo = false);
    }
  }

  // ⬅️ جديد: حذف فيديو موجود مباشرة (endpoint مستقل عن حفظ النموذج)
  Future<void> _removeVideo(String videoUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('حذف الفيديو'),
            content: const Text('هل تريد حذف هذا الفيديو من السيارة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _removingVideoUrl = videoUrl);
    try {
      final updatedVideos = await _companyService.removeCarVideo(
        carId: widget.carId,
        videoUrl: videoUrl,
      );
      if (!mounted) return;
      setState(() => _existingVideos = updatedVideos);
      AppSnackbar.showSuccess(context, title: 'تم حذف الفيديو');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حذف الفيديو',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _removingVideoUrl = null);
    }
  }

  Widget _buildVideosEditor() => EditCarVideosEditor(
    existingVideos: _existingVideos,
    maxVideos: _maxVideos,
    removingVideoUrl: _removingVideoUrl,
    isUploadingVideo: _isUploadingVideo,
    onRemoveVideo: _removeVideo,
    onPickAndUploadVideo: _pickAndUploadVideo,
    accentColor: _primaryBlue,
  );

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F8FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _label(String text) => EditCarFieldLabel(text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('تعديل السيارة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // صورة السيارة (قابلة للتعديل)
            _buildImagesEditor(),
            const SizedBox(height: 20),

            // ⬅️ جديد: قسم فيديوهات السيارة — إضافة/حذف مباشرة (مستقلة
            // عن حفظ بقية بيانات النموذج)، تحديداً لتغطية حالة "أريد
            // رفعه لاحقاً" لسيارة موجودة أصلاً.
            _buildVideosEditor(),
            const SizedBox(height: 20),

            const Text(
              'المعلومات الأساسية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('الموديل'),
                      TextFormField(
                        controller: _modelController,
                        decoration: _fieldDecoration(),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'مطلوب'
                                    : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('الماركة'),
                      TextFormField(
                        controller: _makeController,
                        decoration: _fieldDecoration(),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'مطلوب'
                                    : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('سنة الصنع'),
                      TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration(),
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'مطلوب'
                                    : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('الحالة'),
                      DropdownButtonFormField<String>(
                        value: _condition,
                        decoration: _fieldDecoration(),
                        items: const [
                          DropdownMenuItem(value: 'new', child: Text('جديد')),
                          DropdownMenuItem(
                            value: 'used',
                            child: Text('مستعمل'),
                          ),
                        ],
                        onChanged:
                            (value) =>
                                setState(() => _condition = value ?? 'used'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'الوصف',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _fieldDecoration(hint: 'أضف وصفاً للسيارة...'),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'حفظ التغييرات',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : _deleteCar,
                icon:
                    _isDeleting
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                        : const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'حذف السيارة',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
