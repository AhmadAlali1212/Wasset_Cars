import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mators_car/screens/adsCar/manage/car_picker_sheet.dart';
import 'package:mators_car/services/controllers/rental_ad_service.dart';
import 'package:mators_car/ulits/colors.dart';

/// شاشة إنشاء إعلان تأجير جديد (تعمل لكل من حساب الفرد وحساب المعرض
/// راجع قسم "6. إدارة إعلانات التأجير (Rental Ads)" في ملف Postman).
class AddRentalAdScreen extends StatefulWidget {
  final int? carId;
  final String? carTitle;
  final Map<String, dynamic>? existingAd;

  const AddRentalAdScreen({
    super.key,
    this.carId,
    this.carTitle,
    this.existingAd,
  });

  @override
  State<AddRentalAdScreen> createState() => _AddRentalAdScreenState();
}

class _AddRentalAdScreenState extends State<AddRentalAdScreen> {
  final RentalAdService _rentalAdService = RentalAdService();
  final _formKey = GlobalKey<FormState>();
  final _dailyPriceController = TextEditingController();
  final _monthlyPriceController = TextEditingController();
  final _conditionsController = TextEditingController();

  int? _selectedCarId;
  String? _selectedCarTitle;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingAd != null;

  @override
  void initState() {
    super.initState();
    _selectedCarId = widget.carId;
    _selectedCarTitle = widget.carTitle;

    if (_isEditMode) {
      final ad = widget.existingAd!;
      _dailyPriceController.text =
          (ad['daily_price'] ?? ad['dailyPrice'] ?? '').toString();
      _monthlyPriceController.text =
          (ad['monthly_price'] ?? ad['monthlyPrice'] ?? '').toString();
      _conditionsController.text =
          (ad['rental_conditions'] ?? ad['rentalConditions'] ?? '').toString();
      final car = ad['car'];
      if (car is Map) {
        _selectedCarId = car['id'] as int? ?? ad['car_id'] as int?;
        _selectedCarTitle = '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim();
      }
    }
  }

  @override
  void dispose() {
    _dailyPriceController.dispose();
    _monthlyPriceController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _pickCar() async {
    final car = await CarPickerSheet.show(context);
    if (car == null) return;
    setState(() {
      _selectedCarId = car['id'] as int?;
      _selectedCarTitle = '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCarId == null) {
      AppSnackbar.showWarning(context, title: 'الرجاء اختيار السيارة أولاً');
      return;
    }

    final dailyPrice = double.tryParse(_dailyPriceController.text.trim()) ?? 0;
    if (dailyPrice <= 0) {
      AppSnackbar.showWarning(context, title: 'أدخل سعراً يومياً صحيحاً أكبر من صفر');
      return;
    }
    final monthlyPriceText = _monthlyPriceController.text.trim();
    final monthlyPrice =
        monthlyPriceText.isEmpty ? null : double.tryParse(monthlyPriceText);

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        final adId = widget.existingAd!['id'] as int;
        await _rentalAdService.updateRentalAd(
          rentalAdId: adId,
          dailyPrice: dailyPrice,
          monthlyPrice: monthlyPrice,
          rentalConditions: _conditionsController.text,
        );
        if (!mounted) return;
        AppSnackbar.showSuccess(context, title: 'تم تحديث إعلان التأجير بنجاح');
      } else {
        await _rentalAdService.createRentalAd(
          carId: _selectedCarId!,
          dailyPrice: dailyPrice,
          monthlyPrice: monthlyPrice,
          rentalConditions: _conditionsController.text,
        );
        if (!mounted) return;
        AppSnackbar.showSuccess(
          context,
          title: 'تم إنشاء إعلان التأجير بنجاح',
          subtitle: 'بانتظار مراجعة الأدمن',
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      debugPrint('DioException in add_rental_ad_screen: ${e.response?.statusCode} ${e.response?.data}');
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حفظ إعلان التأجير',
        debugMessage: e,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, title: 'فشلت العملية', debugMessage: e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل إعلان التأجير' : 'إعلان تأجير جديد'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'السيارة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isEditMode ? null : _pickCar,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (_selectedCarTitle == null ||
                                  _selectedCarTitle!.trim().isEmpty)
                              ? 'اضغط لاختيار السيارة'
                              : _selectedCarTitle!,
                        ),
                      ),
                      if (!_isEditMode)
                        const Icon(Icons.chevron_left, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'السعر اليومي',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dailyPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'السعر اليومي (ل.س)',
                  hintText: 'مثال: 150000',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال السعر اليومي';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'الرجاء إدخال سعر صحيح أكبر من صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'السعر الشهري (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _monthlyPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'السعر الشهري (ل.س)',
                  hintText: 'مثال: 3500000',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'شروط التأجير',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _conditionsController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'شروط التأجير',
                  hintText:
                      'مثال: يشترط دفعة تأمين مستردة، وتحديد هوية شخصية سارية المفعول.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF0F4C81),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(_isEditMode ? 'حفظ التعديل' : 'نشر الإعلان'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
