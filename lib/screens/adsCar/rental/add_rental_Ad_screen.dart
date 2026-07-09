import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rental_ad_success_screen.dart';
import 'package:mators_car/ulits/colors.dart';
import '../../../models/car_model.dart';

class AddRentalAdScreen extends StatefulWidget {
  const AddRentalAdScreen({super.key});

  @override
  State<AddRentalAdScreen> createState() => _AddRentalAdScreenState();
}

class _AddRentalAdScreenState extends State<AddRentalAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Form Data
  String _make = '';
  String _model = '';
  String _year = '';
  String _condition = 'used';
  String _dailyPrice = '';
  String _monthlyPrice = '';
  String _rentalConditions = '';
  String _location = '';
  String _description = '';
  List<XFile> _images = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة إعلان تأجير',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(),
                  const SizedBox(height: 24),

                  // Car Images
                  _buildImageUploadSection(),
                  const SizedBox(height: 20),

                  // Car Details
                  _buildCarDetailsSection(),
                  const SizedBox(height: 20),

                  // Rental Prices
                  _buildPriceSection(),
                  const SizedBox(height: 20),

                  // Rental Conditions
                  _buildRentalConditionsField(),
                  const SizedBox(height: 20),

                  // Location
                  _buildLocationField(),
                  const SizedBox(height: 20),

                  // Description
                  _buildDescriptionField(),
                  const SizedBox(height: 30),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إضافة إعلان تأجير جديد',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'املأ النموذج التالي لإضافة إعلان تأجير سيارتك',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صور السيارة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _images.isEmpty
              ? InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'إضافة صور السيارة',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(يمكن إضافة حتى 5 صور)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
              : Stack(
            children: [
              ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length + (_images.length < 5 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: InkWell(
                        onTap: _pickImages,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: AppColors.primary,
                                size: 30,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'إضافة المزيد',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 12, top: 12, bottom: 12),
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(
                                  File(_images[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFiles != null) {
        setState(() {
          if (_images.length + pickedFiles.length <= 5) {
            _images.addAll(pickedFiles);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('يمكنك إضافة 5 صور كحد أقصى'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اختيار الصور: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCarDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات السيارة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Make
              _buildTextFormField(
                label: 'ماركة السيارة',
                icon: Icons.directions_car_rounded,
                onChanged: (value) => _make = value,
              ),
              const SizedBox(height: 16),

              // Model
              _buildTextFormField(
                label: 'طراز السيارة',
                icon: Icons.model_training_rounded,
                onChanged: (value) => _model = value,
              ),
              const SizedBox(height: 16),

              // Year
              _buildTextFormField(
                label: 'سنة الصنع',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                onChanged: (value) => _year = value,
              ),
              const SizedBox(height: 16),

              // Condition
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: InputDecoration(
                  labelText: 'حالة السيارة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.build_rounded,
                    color: Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'used',
                    child: Text('مستعمل'),
                  ),
                  DropdownMenuItem(
                    value: 'new',
                    child: Text('جديد'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _condition = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أسعار التأجير',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPriceField(
                      label: 'السعر اليومي (ل.س)',
                      onChanged: (value) => _dailyPrice = value,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceField(
                      label: 'السعر الشهري (ل.س)',
                      onChanged: (value) => _monthlyPrice = value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'سيتم عرض هذه الأسعار للمستأجرين المحتملين',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required String label,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(
          Icons.attach_money_rounded,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        if (double.tryParse(value) == null) return 'أدخل رقمًا صحيحًا';
        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _buildRentalConditionsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شروط التأجير',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'اكتب شروط التأجير هنا',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.assignment_rounded,
                color: Colors.grey.shade600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
              return null;
            },
            onChanged: (value) => _rentalConditions = value,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الموقع',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'حدد موقع السيارة',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.location_on_rounded,
                color: Colors.grey.shade600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
              return null;
            },
            onChanged: (value) => _location = value,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وصف السيارة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'أضف وصفًا للسيارة',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.description_rounded,
                color: Colors.grey.shade600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 4,
            onChanged: (value) => _description = value,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        onPressed: _submitForm,
        child: const Text(
          'نشر الإعلان',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final car = Car(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: 1,
        make: _make,
        model: _model,
        year: int.tryParse(_year) ?? 2020,
        condition: _condition,
        description: _description,
        location: _location,
        images: _images.map((e) => e.path).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userName: '',
      );

      final rentalAd = Ad(
        id: 0,
        carId: car.id,
        userId: 1,
        price: _dailyPrice,
        status: "pending",
        isFeatured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: car,
        dailyPrice: _dailyPrice,
        monthlyPrice: _monthlyPrice,
        rentalConditions: _rentalConditions,
        location: _location,
        auctions: [],
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RentalAdSuccessScreen(ad: rentalAd),
        ),
      );
    }
  }
}