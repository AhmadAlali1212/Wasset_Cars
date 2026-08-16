import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/screens/adsCar/manage/add_rental_ad_screen.dart';
import 'package:mators_car/screens/adsCar/manage/add_sale_ad_screen.dart';
import 'package:mators_car/screens/company/map_location_picker_screen.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/ulits/colors.dart';

class CompanyAddCarWizardScreen extends StatefulWidget {
  const CompanyAddCarWizardScreen({super.key});

  @override
  State<CompanyAddCarWizardScreen> createState() =>
      _CompanyAddCarWizardScreenState();
}

class _CompanyAddCarWizardScreenState extends State<CompanyAddCarWizardScreen> {
  final CompanyService _companyService = CompanyService();
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxImages = 5;

  int _currentStep = 0;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _condition = 'مستعملة';
  // String _carType = 'سيدان';
  final List<String> _locations = [];
  final List<XFile> _images = [];

  // ✅ إحداثيات الموقع المختار من الخريطة
  double? _latitude;
  double? _longitude;

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 70);

      if (pickedFiles.isEmpty) {
        return;
      }

      if (_images.length >= _maxImages) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يمكنك إضافة 5 صور كحد أقصى'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final remainingSlots = _maxImages - _images.length;
      final filesToAdd = pickedFiles.take(remainingSlots).toList();

      if (filesToAdd.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم الوصول إلى الحد الأقصى وهو 5 صور'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      setState(() {
        _images.addAll(filesToAdd);
      });

      if (filesToAdd.length < pickedFiles.length && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الصور المتبقية حتى الحد الأقصى وهو 5 صور'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء اختيار الصور: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showLocationOptions(String location) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('تعديل الموقع'),
                onTap: () {
                  Navigator.pop(context);
                  _editLocation(location);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('حذف الموقع'),
                onTap: () {
                  setState(() {
                    _locations.remove(location);
                    if (_locationController.text == location) {
                      _locationController.clear();
                    }
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addLocation() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('إضافة موقع جديد'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'أدخل الموقع هنا'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    setState(() {
                      _locations.add(value);
                      _locationController.text = value;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
    );
  }

  void _editLocation(String location) {
    final controller = TextEditingController(text: location);
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تعديل الموقع'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'أدخل الموقع الجديد'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    final index = _locations.indexOf(location);
                    if (index != -1) {
                      setState(() {
                        _locations[index] = value;
                        if (_locationController.text == location) {
                          _locationController.text = value;
                        }
                      });
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
    );
  }

  // ✅ فتح شاشة الخريطة واستقبال الإحداثيات + العنوان النصي المُقترح
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
      if (!_locations.contains(result.address)) {
        _locations.add(result.address);
      }
    });
  }

  void _openLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر موقع السيارة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              // ✅ الخيار الأساسي الجديد: تحديد الموقع مباشرة على الخريطة
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openMapPicker();
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('تحديد الموقع على الخريطة'),
                style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_locations.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'أو اختر من المواقع المحفوظة',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ..._locations.map((location) {
                final isSelected = _locationController.text == location;
                return Card(
                  color:
                      isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surface,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(location),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        Navigator.pop(context);
                        _showLocationOptions(location);
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _locationController.text = location;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _addLocation();
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('إضافة موقع نصي يدوياً'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitCar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ التأكد من وجود إحداثيات قبل الإرسال (اختياري حسب متطلبات الـ Backend)
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد موقع السيارة على الخريطة')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isSubmitting = true;
    });

    try {
      // تحويل القيمة العربية إلى القيمة المقبولة في الـ Backend
      final apiCondition = _condition == 'جديد' ? 'new' : 'used';

      final fields = {
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()) ?? 0,
        'condition': apiCondition, // <-- استخدام القيمة المحولة هنا
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        // ✅ الإحداثيات كما يتوقعها الـ Backend (انظر Postman Collection)
        'latitude': _latitude!.toStringAsFixed(6),
        'longitude': _longitude!.toStringAsFixed(6),
        //'price': double.tryParse(_priceController.text.trim()) ?? 0,
        //'vehicle_identifier': 'VIN123456'.trim(),
      };

      // إزالة car_type إذا لم يكن موجوداً بالواجهة أو إرساله فقط إذا كان محدداً
      // ... قم باستكمال باقي الدالة

      final response = await _companyService.addCar(
        fields: fields,
        imageFiles: _images.map((item) => File(item.path)).toList(),
      );

      if (!mounted) return;

      final carId = _extractCarId(response);
      if (carId != null) {
        final carTitle =
            '${_makeController.text.trim()} ${_modelController.text.trim()}'
                .trim();

        final choice = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'هل تريد إنشاء إعلان لهذه السيارة الآن؟',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.sell_outlined),
                      title: const Text('إعلان بيع'),
                      onTap: () => Navigator.pop(sheetContext, 'sale'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.car_rental_outlined),
                      title: const Text('إعلان تأجير'),
                      onTap: () => Navigator.pop(sheetContext, 'rental'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: const Text('لاحقاً'),
                      onTap: () => Navigator.pop(sheetContext, null),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (!mounted) return;

        if (choice == 'sale') {
          final price = double.tryParse(_priceController.text.trim());
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AddSaleAdScreen(
                    carId: carId,
                    carTitle: carTitle,
                    initialPrice: (price != null && price > 0) ? price : null,
                  ),
            ),
          );
        } else if (choice == 'rental') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AddRentalAdScreen(carId: carId, carTitle: carTitle),
            ),
          );
        }
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم إرسال السيارة للمراجعة بنجاح')),
      );
      navigator.pop();
    } on DioException catch (e, stackTrace) {
      debugPrint('DioException while adding car: ${e.toString()}');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showErrorSnackBar(_formatSubmitError(e));
      }
    } catch (e, stackTrace) {
      debugPrint('Unexpected error while adding car: ${e.toString()}');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showErrorSnackBar(_formatSubmitError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showErrorSnackBarWithDetails(String message, String details) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'تفاصيل',
          textColor: Colors.white,
          onPressed: () {
            _showErrorDetailsDialog('تفاصيل الخطأ', details);
          },
        ),
      ),
    );
  }

  void _showErrorDetailsDialog(String title, String details) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: SelectableText(
              details.isNotEmpty ? details : 'لا توجد تفاصيل إضافية',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Clipboard.setData(ClipboardData(text: details));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ التفاصيل إلى الحافظة')),
                );
              },
              child: const Text('نسخ'),
            ),
          ],
        );
      },
    );
  }

  String _detailedErrorString(Object error, StackTrace? stackTrace) {
    final buffer = StringBuffer();

    if (error is DioException) {
      buffer.writeln('DioException: ${error.message ?? ''}');
      buffer.writeln('Status code: ${error.response?.statusCode}');
      try {
        final data = error.response?.data;
        if (data != null) {
          if (data is String) {
            buffer.writeln('Response: $data');
          } else {
            buffer.writeln(
              'Response: ${const JsonEncoder.withIndent('  ').convert(data)}',
            );
          }
        }
      } catch (_) {
        buffer.writeln('Response: ${error.response?.data}');
      }
    } else {
      buffer.writeln(error.toString());
    }

    if (stackTrace != null) {
      buffer.writeln('\nStackTrace:\n${stackTrace.toString()}');
    }

    return buffer.toString();
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
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(data);
    final errors = map['errors'];
    final lines = <String>[];

    if (errors is Map && errors.isNotEmpty) {
      errors.forEach((key, value) {
        if (value is List) {
          final values = value.map((item) => item.toString()).join(', ');
          if (values.isNotEmpty) {
            lines.add('$key: $values');
          }
        } else if (value is String && value.trim().isNotEmpty) {
          lines.add('$key: ${value.trim()}');
        }
      });
    } else if (errors is String && errors.trim().isNotEmpty) {
      lines.add(errors.trim());
    }

    if (lines.isNotEmpty) {
      return lines.join('\n');
    }

    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
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

  int? _extractCarId(Map<String, dynamic> response) {
    final candidates = [
      response['id'],
      response['car_id'],
      response['carId'],
      response['data'] is Map ? response['data']['id'] : null,
      response['data'] is Map ? response['data']['car_id'] : null,
      response['car'] is Map ? response['car']['id'] : null,
      response['car'] is Map ? response['car']['car_id'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate is int) return candidate;
      if (candidate is String && candidate.trim().isNotEmpty) {
        final parsed = int.tryParse(candidate);
        if (parsed != null) return parsed;
      }
    }
    return null;
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
              _buildLocationField(),
              // _buildTextField(
              //   controller: _priceController,
              //   label: 'السعر',
              //   keyboardType: TextInputType.number,
              //   validator:
              //       (value) =>
              //           value == null  value.isEmpty
              //               ? 'الرجاء إدخال السعر'
              //               : null,
              // ),
              // const SizedBox(height: 12),
              // _buildDropdown(
              //   label: 'نوع السيارة',
              //   value: _carType,
              //   options: const ['سيدان', 'SUV', 'بيك أب', 'هاتشباك'],
              //   onChanged: (value) {
              //     setState(() {
              //       _carType = value!;
              //     });
              //   },
              // ),
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
            foregroundColor: Colors.white,
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
                options: const ['جديد', 'مستعملة'],
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
              _reviewRow('الموقع', _locationController.text),
              _reviewRow(
                'الإحداثيات',
                (_latitude != null && _longitude != null)
                    ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                    : '',
              ),
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
          fillColor: AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: _openLocationPicker,
        child: AbsorbPointer(
          child: TextFormField(
            controller: _locationController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء اختيار موقع السيارة';
              }
              return null;
            },
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
        initialValue: value,
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
            foregroundColor: Colors.white,
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
