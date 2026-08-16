import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/ulits/constans.dart';

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

  @override
  void initState() {
    super.initState();
    final car = widget.car;

    _makeController = TextEditingController(text: (car['make'] ?? car['name'] ?? '').toString());
    _modelController = TextEditingController(text: (car['model'] ?? '').toString());
    _yearController = TextEditingController(text: (car['year'] ?? '').toString());
    _descriptionController = TextEditingController(text: (car['description'] ?? '').toString());
    _condition = (car['condition'] ?? 'used').toString();
    _primaryImageUrl = _getPrimaryImage(car['images'] ?? car['image']);
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
      if (firstItem is Map && firstItem['url'] != null) raw = firstItem['url'].toString();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الحد الأقصى $_maxImages صور')),
      );
      return;
    }
    try {
      final remainingSlots = _maxImages - _newImages.length;
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;
      final filesToAdd = picked.take(remainingSlots).toList();
      setState(() => _newImages.addAll(filesToAdd));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر اختيار الصور: $e')));
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
      'year': int.tryParse(_yearController.text.trim()) ?? _yearController.text.trim(),
      'condition': _condition,
      'description': _descriptionController.text.trim(),
    };

    // نحافظ على الإحداثيات الأصلية إن وُجدت لأن الـ endpoint يقبلها ضمن نفس الطلب
    if (widget.car['latitude'] != null) fields['latitude'] = widget.car['latitude'];
    if (widget.car['longitude'] != null) fields['longitude'] = widget.car['longitude'];

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التعديلات: $msg')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // حذف السيارة عبر DELETE /cars/{car_id}
  Future<void> _deleteCar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف السيارة'),
        content: const Text('هل أنت متأكد من حذف هذه السيارة؟ لا يمكن التراجع عن هذا الإجراء.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف السيارة بنجاح')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حذف السيارة: $msg')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _buildImagesEditor() {
    // إذا اختار المستخدم صوراً جديدة، نعرضها بدل الصورة القديمة من السيرفر
    if (_newImages.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('الصور الجديدة (${_newImages.length}/$_maxImages) — ستستبدل الصور الحالية'),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length + (_newImages.length < _maxImages ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == _newImages.length) {
                  return _addImageTile();
                }
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(_newImages[index].path),
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeNewImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    // لا صور جديدة بعد: نعرض الصورة الحالية من السيرفر مع زر لتغييرها
    return GestureDetector(
      onTap: _pickImages,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _primaryImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _primaryImageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (_, __) => Container(color: const Color(0xFFE9ECF2)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFE9ECF2),
                        child: const Icon(Icons.directions_car, size: 48, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFE9ECF2),
                      child: const Icon(Icons.directions_car, size: 48, color: Colors.grey),
                    ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('تغيير الصور', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addImageTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.add_a_photo_outlined, color: _primaryBlue),
      ),
    );
  }

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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      );

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

            const Text('المعلومات الأساسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
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
                          DropdownMenuItem(value: 'used', child: Text('مستعمل')),
                        ],
                        onChanged: (value) => setState(() => _condition = value ?? 'used'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('الوصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ التغييرات', style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : _deleteCar,
                icon: _isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('حذف السيارة', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
