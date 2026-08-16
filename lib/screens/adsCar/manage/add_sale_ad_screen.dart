import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mators_car/screens/adsCar/manage/car_picker_sheet.dart';
import 'package:mators_car/services/ads_service.dart';
import 'package:mators_car/ulits/colors.dart';

/// شاشة إنشاء إعلان بيع جديد (تعمل لكل من حساب الفرد وحساب المعرض
/// بنفس الطريقة تماماً لأن الـ API واحد لكليهما - راجع قسم
/// "5. إدارة إعلانات البيع (Sale Ads)" في ملف Postman).
///
/// - إن مُرِّر [carId] جاهزاً (مثلاً مباشرة بعد إضافة سيارة جديدة) تُخطى خطوة الاختيار.
/// - إن مُرِّر [existingAd] فهذا يعني أننا في وضع "تعديل السعر" لإعلان موجود.
class AddSaleAdScreen extends StatefulWidget {
  final int? carId;
  final String? carTitle;
  final double? initialPrice;
  final Map<String, dynamic>? existingAd;

  const AddSaleAdScreen({
    super.key,
    this.carId,
    this.carTitle,
    this.initialPrice,
    this.existingAd,
  });

  @override
  State<AddSaleAdScreen> createState() => _AddSaleAdScreenState();
}

class _AddSaleAdScreenState extends State<AddSaleAdScreen> {
  final AdsService _adsService = AdsService();
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  int? _selectedCarId;
  String? _selectedCarTitle;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingAd != null;

  @override
  void initState() {
    super.initState();
    _selectedCarId = widget.carId;
    _selectedCarTitle = widget.carTitle;
    if (widget.initialPrice != null && widget.initialPrice! > 0) {
      _priceController.text = widget.initialPrice!.toString();
    }

    if (_isEditMode) {
      final ad = widget.existingAd!;
      _priceController.text = (ad['price'] ?? '').toString();
      final car = ad['car'];
      if (car is Map) {
        _selectedCarId = car['id'] as int? ?? ad['car_id'] as int?;
        _selectedCarTitle = '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim();
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار السيارة أولاً')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل سعراً صحيحاً أكبر من صفر')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (_isEditMode) {
        final adId = widget.existingAd!['id'] as int;
        await _adsService.updateAd(adId: adId, price: price);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('تم تحديث سعر الإعلان بنجاح')),
        );
      } else {
        await _adsService.createAd(carId: _selectedCarId!, price: price);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء إعلان البيع بنجاح، بانتظار مراجعة الأدمن'),
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      print("Status Code: ${e.response?.statusCode}");
      print("Response: ${e.response?.data}");

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.response?.data.toString() ?? e.message ?? "حدث خطأ"),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('فشلت العملية: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل إعلان البيع' : 'إعلان بيع جديد'),
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
                'سعر البيع',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'السعر (ل.س)',
                  hintText: 'مثال: 15000000',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال السعر';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'الرجاء إدخال سعر صحيح أكبر من صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
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
