import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rental_ad_success_screen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/rental/rental_ads/add_rental_ad_widgets.dart';
import 'package:mators_car/data/models/car_model.dart';

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
        title: const Text(
          'إضافة إعلان تأجير',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.05), Colors.white],
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
                  const RentalAdHeaderSection(),
                  const SizedBox(height: 24),

                  // Car Images
                  RentalAdImageUploadSection(
                    images: _images,
                    onPickImages: _pickImages,
                    onRemoveImage: _removeImage,
                  ),
                  const SizedBox(height: 20),

                  // Car Details
                  RentalAdCarDetailsSection(
                    onMakeChanged: (value) => _make = value,
                    onModelChanged: (value) => _model = value,
                    onYearChanged: (value) => _year = value,
                    condition: _condition,
                    onConditionChanged: (value) {
                      setState(() {
                        _condition = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Rental Prices
                  RentalAdPriceSection(
                    onDailyPriceChanged: (value) => _dailyPrice = value,
                    onMonthlyPriceChanged: (value) => _monthlyPrice = value,
                  ),
                  const SizedBox(height: 20),

                  // Rental Conditions
                  RentalAdMultilineField(
                    sectionLabel: 'شروط التأجير',
                    hintLabel: 'اكتب شروط التأجير هنا',
                    icon: Icons.assignment_rounded,
                    maxLines: 4,
                    onChanged: (value) => _rentalConditions = value,
                  ),
                  const SizedBox(height: 20),

                  // Location
                  RentalAdMultilineField(
                    sectionLabel: 'الموقع',
                    hintLabel: 'حدد موقع السيارة',
                    icon: Icons.location_on_rounded,
                    onChanged: (value) => _location = value,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  RentalAdMultilineField(
                    sectionLabel: 'وصف السيارة',
                    hintLabel: 'أضف وصفًا للسيارة',
                    icon: Icons.description_rounded,
                    maxLines: 4,
                    required: false,
                    onChanged: (value) => _description = value,
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  RentalAdSubmitButton(onPressed: _submitForm),
                ],
              ),
            ),
          ),
        ),
      ),
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
            AppSnackbar.showWarning(
              context,
              title: 'يمكنك إضافة 5 صور كحد أقصى',
            );
          }
        });
      }
    } catch (e) {
      AppSnackbar.showError(
        context,
        title: 'تعذّر اختيار الصور',
        debugMessage: e,
      );
    }
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
