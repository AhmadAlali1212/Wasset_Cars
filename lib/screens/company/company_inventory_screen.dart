import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/ulits/constans.dart';
import 'edit_car_screen.dart';

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
        return 'مقبولة';
      case 'pending':
        return 'بانتظار المراجعة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return status ?? 'غير محدد';
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
      final status = (car['approval_status'] ?? car['status'] ?? 'pending').toString();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحديد معرّف السيارة')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('حذف السيارة'),
            content: Text(
              'هل أنت متأكد من حذف $make $model؟ لا يمكن التراجع عن هذا الإجراء.',
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

    try {
      await _companyService.deleteCar(carId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف السيارة بنجاح')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حذف السيارة: $msg')));
    }
  }

  // طلب فحص فني للسيارة (POST /cars/{id}/request-inspection)
  Future<void> _requestInspection(Map<String, dynamic> car) async {
    final carId = _extractCarId(car);
    if (carId == null) return;
    try {
      await _companyService.requestInspection(carId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم طلب الفحص الفني بنجاح')));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل طلب الفحص: $msg')));
    }
  }

  // فتح شاشة التعديل (PUT /cars/{car_id})
  void _openEdit(Map<String, dynamic> car) {
    final carId = _extractCarId(car);
    if (carId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحديد معرّف السيارة')));
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
                Text('الماركة: $make'),
                const SizedBox(height: 8),
                Text('الموديل: $model'),
                const SizedBox(height: 8),
                Text('سنة الصنع: $year'),
                const SizedBox(height: 8),
                Text('الحالة التشغيلية: $conditionText'),
                const SizedBox(height: 8),
                Text('حالة الطلب: ${_translateStatus(status)}'),
                const SizedBox(height: 12),
                const Text(
                  'الوصف:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'ابحث عن سيارة...',
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixIcon: const Icon(Icons.search, color: Colors.black45),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // شرائح الفلترة حسب حالة المراجعة
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = _selectedStatus == filter['key'];
                return ChoiceChip(
                  label: Text(filter['label']!),
                  selected: selected,
                  onSelected:
                      (_) => setState(() => _selectedStatus = filter['key']!),
                  showCheckmark: false,
                  selectedColor: _primaryBlue,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected ? _primaryBlue : const Color(0xFFE1E4EA),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                );
              },
            ),
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
                  final errorMsg = snapshot.error.toString().replaceAll(
                    'Exception: ',
                    '',
                  );
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.emptyStateIcon,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.emptyStateTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.emptyStateSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (cars.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد نتائج مطابقة للبحث/الفلتر',
                      style: TextStyle(fontSize: 15, color: Colors.black45),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: cars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final car = cars[index];
                      return _CarCard(
                        car: car,
                        translateStatus: _translateStatus,
                        getStatusColor: _getStatusColor,
                        imageUrl: _getPrimaryImage(
                          car['images'] ?? car['image'],
                        ),
                        onTap: () => _showDetailsDialog(car),
                        onEdit: () => _openEdit(car),
                        onDelete: () => _confirmAndDelete(car),
                        onInspect:
                            widget.showInspectionAction
                                ? () => _requestInspection(car)
                                : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final Map<String, dynamic> car;
  final String Function(String?) translateStatus;
  final Color Function(String?) getStatusColor;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onInspect;

  const _CarCard({
    required this.car,
    required this.translateStatus,
    required this.getStatusColor,
    required this.imageUrl,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final make = car['make'] ?? car['name'] ?? 'غير محدد';
    final model = car['model'] ?? 'غير محدد';
    final year = car['year']?.toString() ?? '-';
    final rawCondition = car['condition'] ?? 'used';
    final conditionText = rawCondition == 'new' ? 'جديد' : 'أوتوماتيك';
    final status = (car['approval_status'] ?? car['status'] ?? 'pending').toString();
    final mileage = car['mileage']?.toString() ?? car['odometer']?.toString();
    final city = car['city'] ?? car['location'] ?? 'دمشق';
    final statusColor = getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة السيارة مع شارة الحالة وأيقونة المفضلة
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child:
                      imageUrl != null
                          ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            placeholder:
                                (_, __) => Container(
                                  color: const Color(0xFFF0F0F0),
                                ),
                            errorWidget:
                                (_, __, ___) => Container(
                                  color: const Color(0xFFF0F0F0),
                                  child: const Icon(
                                    Icons.directions_car,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                          : Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(
                              Icons.directions_car,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      translateStatus(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$make $model $year',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            city,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            year,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (mileage != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.speed_outlined,
                              size: 14,
                              color: Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$mileage كم',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          const Icon(
                            Icons.settings_outlined,
                            size: 14,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conditionText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF14245C),
                        ),
                        label: const Text(
                          'تعديل',
                          style: TextStyle(color: Color(0xFF14245C)),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                      ),
                      if (onInspect != null)
                        TextButton.icon(
                          onPressed: onInspect,
                          icon: const Icon(
                            Icons.health_and_safety_outlined,
                            size: 16,
                            color: Colors.teal,
                          ),
                          label: const Text(
                            'فحص فني',
                            style: TextStyle(color: Colors.teal),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'حذف',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
