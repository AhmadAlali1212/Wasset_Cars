import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/services/company_service.dart';

class CompanyAddCarWizardScreen extends StatefulWidget {
  const CompanyAddCarWizardScreen({super.key});

  @override
  State<CompanyAddCarWizardScreen> createState() =>
      _CompanyAddCarWizardScreenState();
}

class _CompanyAddCarWizardScreenState extends State<CompanyAddCarWizardScreen> {
  final CompanyService _companyService = CompanyService();
  final ImagePicker _imagePicker = ImagePicker();

  int _currentStep = 0;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _condition = 'مستعملة';
  String _carType = 'سيدان';
  final List<XFile> _images = [];

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.clear();
        _images.addAll(pickedFiles.take(5));
      });
    }
  }

  Future<void> _submitCar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fields = {
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()) ?? 0,
        'condition': _condition,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'car_type': _carType,
        'latitude': 0,
        'longitude': 0,
      };

      await _companyService.addCar(
        fields: fields,
        imageFiles: _images.map((item) => File(item.path)).toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال السيارة إلى المعرض')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إضافة السيارة: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة سيارة جديدة'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _buildStepperHeader(),
            const SizedBox(height: 16),
            Expanded(child: Form(key: _formKey, child: _buildStepContent())),
            const SizedBox(height: 14),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final steps = ['معلومات السيارة', 'صور السيارة', 'المواصفات', 'المراجعة'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          steps.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isActive = index == _currentStep;
            final isDone = index < _currentStep;

            return Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        isDone
                            ? const Color(0xFF0F4C81)
                            : isActive
                            ? const Color(0xFF334155)
                            : Colors.white,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isDone ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.black : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _makeController,
                label: 'الماركة',
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'الرجاء إدخال الماركة'
                            : null,
              ),
              _buildTextField(
                controller: _modelController,
                label: 'الموديل',
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'الرجاء إدخال الموديل'
                            : null,
              ),
              _buildTextField(
                controller: _yearController,
                label: 'سنة الصنع',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال سنة الصنع';
                  }
                  if (int.tryParse(value) == null) {
                    return 'أدخل سنة صالحة';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _priceController,
                label: 'السعر',
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'الرجاء إدخال السعر'
                            : null,
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'نوع السيارة',
                value: _carType,
                options: const ['سيدان', 'SUV', 'بيك أب', 'هاتشباك'],
                onChanged: (value) {
                  setState(() {
                    _carType = value!;
                  });
                },
              ),
            ],
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختر صور السيارة (حتى 5 صور)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('رفع الصور'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: _images.isEmpty ? 1 : _images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  if (_images.isEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          'لم يتم اختيار صور بعد',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_images[index].path),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 2:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdown(
                label: 'الحالة',
                value: _condition,
                options: const ['جديدة', 'مستعملة'],
                onChanged: (value) {
                  setState(() {
                    _condition = value!;
                  });
                },
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _descriptionController,
                label: 'الوصف',
                maxLines: 5,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'الرجاء إدخال وصف للسيارة'
                            : null,
              ),
            ],
          ),
        );
      case 3:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewRow('الماركة', _makeController.text),
              _reviewRow('الموديل', _modelController.text),
              _reviewRow('السنة', _yearController.text),
              _reviewRow('السعر', _priceController.text),
              _reviewRow('نوع السيارة', _carType),
              _reviewRow('الحالة', _condition),
              _reviewRow('الوصف', _descriptionController.text),
              const SizedBox(height: 16),
              const Text(
                'عدد الصور المختارة',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('${_images.length} صورة'),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
        ),
        items:
            options
                .map(
                  (option) =>
                      DropdownMenuItem(value: option, child: Text(option)),
                )
                .toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed:
                _currentStep == 0
                    ? null
                    : () {
                      setState(() {
                        _currentStep -= 1;
                      });
                    },
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
            onPressed:
                _isSubmitting
                    ? null
                    : _currentStep == 3
                    ? _submitCar
                    : () {
                      if (_currentStep == 0 &&
                          !_formKey.currentState!.validate()) {
                        return;
                      }
                      setState(() {
                        _currentStep += 1;
                      });
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child:
                _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_currentStep == 3 ? 'إرسال' : 'متابعة'),
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value.isNotEmpty ? value : '-')),
        ],
      ),
    );
  }
}
