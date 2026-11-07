import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/ulits/constant.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'edit_car_screen.dart';
import 'package:mators_car/widgets/company/company_inventory_widgets.dart';

class CompanyInventoryScreen extends StatefulWidget {
  final String title;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final IconData emptyStateIcon;
  // شاشة إضافة سيارة جديدة تختلف بين الفرد والمعرض (نموذج بسيط مقابل
  // معالج بعدة خطوات)، فنستقبلها كدالة بناء بدل ربطها مباشرة بمسار ثابت.
  final WidgetBuilder addCarScreenBuilder;
  // فحص فني متاح لكل من الفرد والمعرض حسب الـ API، لكن يمكن إخفاؤه لو
  // احتاج الاستخدام لاحقاً تخصيصاً مختلفاً بين الحسابين.
  final bool showInspectionAction;

  const CompanyInventoryScreen({
    super.key,
    this.title = 'سيارات المعرض',
    this.emptyStateTitle = 'لا توجد سيارات في المعرض بعد',
    this.emptyStateSubtitle = 'استخدم زر الإضافة لإدخال أول سيارة لك',
    this.emptyStateIcon = Icons.storefront_outlined,
    required this.addCarScreenBuilder,
    this.showInspectionAction = true,
  });

  @override
  State<CompanyInventoryScreen> createState() => _CompanyInventoryScreenState();
}

class _CompanyInventoryScreenState extends State<CompanyInventoryScreen> {
  final CompanyService _companyService = CompanyService();
  final TextEditingController _searchController = TextEditingController();

  static const Color _primaryBlue = Color(0xFF14245C);

  late Future<List<Map<String, dynamic>>> _carsFuture;

  String _searchQuery = '';
  // 'all' | 'pending' | 'approved' | 'rejected'
  String _selectedStatus = 'all';

  final List<Map<String, String>> _filters = const [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'pending', 'label': 'بانتظار المراجعة'},
    {'key': 'approved', 'label': 'مقبولة'},
    {'key': 'rejected', 'label': 'مرفوضة'},
  ];

  @override
  void initState() {
    super.initState();
    _carsFuture = _companyService.getCompanyCars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _carsFuture = _companyService.getCompanyCars();
    });
    await _carsFuture;
  }

  // تحويل حالة السيارة من السيرفر إلى نص عربي وشهادة مرئية
  String _translateStatus(String? status) {
    switch (status) {
      case 'approved':
        return context.tr('approved');
      case 'pending':
        return context.tr('pending_review');
      case 'rejected':
        return context.tr('rejected');
      default:
        return status ?? context.tr('unspecified');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF1DB954);
      case 'pending':
        return const Color(0xFFF5A623);
      case 'rejected':
        return const Color(0xFFE84545);
      default:
        return Colors.grey;
    }
  }

  // استخراج الصورة الأولى إن وجدت
  String? _getPrimaryImage(dynamic imagesData) {
    String? raw;
    if (imagesData is List && imagesData.isNotEmpty) {
      final firstItem = imagesData.first;
      if (firstItem is String) raw = firstItem;
      if (firstItem is Map && firstItem['url'] != null) {
        raw = firstItem['url'].toString();
      }
      if (firstItem is Map && firstItem['image_path'] != null) {
        raw = firstItem['image_path'].toString();
      }
    } else if (imagesData is String && imagesData.isNotEmpty) {
      raw = imagesData;
    }
    return AppConstants.resolveImageUrl(raw);
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> cars) {
    return cars.where((car) {
      final status =
          (car['approval_status'] ?? car['status'] ?? 'pending').toString();
      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;

      if (!matchesStatus) return false;
      if (_searchQuery.trim().isEmpty) return true;

      final make = (car['make'] ?? car['name'] ?? '').toString().toLowerCase();
      final model = (car['model'] ?? '').toString().toLowerCase();
      final query = _searchQuery.trim().toLowerCase();
      return make.contains(query) || model.contains(query);
    }).toList();
  }

  // يحاول استخراج معرّف السيارة كرقم صحيح (deleteCar/updateCar في CompanyService يتوقعان int)
  int? _extractCarId(Map<String, dynamic> car) {
    final rawId = car['id'];
    if (rawId is int) return rawId;
    if (rawId != null) return int.tryParse(rawId.toString());
    return null;
  }

  // حذف سيارة من السيرفر بعد تأكيد المستخدم (DELETE /cars/{car_id})
  Future<void> _confirmAndDelete(Map<String, dynamic> car) async {
    final carId = _extractCarId(car);
    final make = car['make'] ?? car['name'] ?? '';
    final model = car['model'] ?? '';

    if (carId == null) {
      AppSnackbar.showError(context, title: context.tr('car_id_unavailable'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(context.tr('delete_car')),
            content: Text(
              '${context.tr('confirm_delete_car')} $make $model؟ ${context.tr('cannot_undo')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  context.tr('delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _companyService.deleteCar(carId);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: context.tr('car_deleted'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: context.tr('delete_car_failed'),
        debugMessage: e,
      );
    }
  }

  // طلب فحص فني للسيارة (POST /cars/{id}/request-inspection)
  Future<void> _requestInspection(Map<String, dynamic> car) async {
    final carId = _extractCarId(car);
    if (carId == null) return;
    try {
      await _companyService.requestInspection(carId);
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        title: context.tr('inspection_requested'),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: context.tr('inspection_request_failed'),
        debugMessage: e,
      );
    }
  }

  // فتح شاشة التعديل (PUT /cars/{car_id})
  void _openEdit(Map<String, dynamic> car) {
    final carId = _extractCarId(car);
    if (carId == null) {
      AppSnackbar.showError(context, title: context.tr('car_id_unavailable'));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCarScreen(carId: carId, car: car)),
    ).then((updated) {
      if (updated == true) _refresh();
    });
  }

  void _showDetailsDialog(Map<String, dynamic> car) {
    final make = car['make'] ?? car['name'] ?? 'غير محدد';
    final model = car['model'] ?? 'غير محدد';
    final year = car['year']?.toString() ?? '-';
    final rawCondition = car['condition'] ?? 'used';
    final conditionText = rawCondition == 'new' ? 'جديد' : 'مستعملة';
    final status = car['approval_status'] ?? car['status'] ?? 'pending';
    final description = car['description'] ?? 'لا يوجد وصف';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('$make $model'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${context.tr('make')}: $make'),
                const SizedBox(height: 8),
                Text('${context.tr('model')}: $model'),
                const SizedBox(height: 8),
                Text('${context.tr('manufacture_year')}: $year'),
                const SizedBox(height: 8),
                Text('${context.tr('condition')}: $conditionText'),
                const SizedBox(height: 8),
                Text(
                  '${context.tr('request_status')}: ${_translateStatus(status)}',
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('description'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('close')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: _primaryBlue,
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: widget.addCarScreenBuilder),
                ).then((added) {
                  if (added == true) _refresh();
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // شريط البحث
          InventorySearchBar(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          // شرائح الفلترة حسب حالة المراجعة
          InventoryFilterChips(
            filters: _filters,
            selectedStatus: _selectedStatus,
            primaryColor: _primaryBlue,
            onSelect: (key) => setState(() => _selectedStatus = key!),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _carsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final errorMsg = ApiException.userMessage(snapshot.error);
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'تعذر جلب سيارات المعرض\n$errorMsg',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final allCars = snapshot.data ?? [];
                final cars = _applyFilters(allCars);

                if (allCars.isEmpty) {
                  return InventoryEmptyState(
                    icon: widget.emptyStateIcon,
                    title: widget.emptyStateTitle,
                    subtitle: widget.emptyStateSubtitle,
                  );
                }

                return InventoryCarsList(
                  cars: cars,
                  onRefresh: _refresh,
                  imageUrlFor:
                      (car) => _getPrimaryImage(car['images'] ?? car['image']),
                  translateStatus: _translateStatus,
                  getStatusColor: _getStatusColor,
                  onTapCar: _showDetailsDialog,
                  onEditCar: _openEdit,
                  onDeleteCar: _confirmAndDelete,
                  onInspectCar:
                      widget.showInspectionAction ? _requestInspection : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
