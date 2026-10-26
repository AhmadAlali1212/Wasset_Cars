import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/rental_ad_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

/// شاشة يديرها مالك إعلان التأجير لتحديد الأيام التي تكون فيها سيارته
/// غير متاحة للتأجير (صيانة، محجوزة خارج التطبيق، إلخ)، بشكل منفصل عن
/// الحجوزات الفعلية داخل التطبيق. الفترات المضافة هنا تظهر معطّلة مباشرة
/// في تقويم الحجز عند أي مستخدم يحاول حجز هذه السيارة.
class ManageRentalAvailabilityScreen extends StatefulWidget {
  final int rentalAdId;
  final String? carTitle;

  const ManageRentalAvailabilityScreen({
    super.key,
    required this.rentalAdId,
    this.carTitle,
  });

  @override
  State<ManageRentalAvailabilityScreen> createState() =>
      _ManageRentalAvailabilityScreenState();
}

class _ManageRentalAvailabilityScreenState
    extends State<ManageRentalAvailabilityScreen> {
  final RentalAdService _rentalAdService = RentalAdService();
  late Future<List<Map<String, dynamic>>> _rangesFuture;

  @override
  void initState() {
    super.initState();
    _rangesFuture = _rentalAdService.getUnavailableRanges(widget.rentalAdId);
  }

  void _refresh() {
    setState(() {
      _rangesFuture = _rentalAdService.getUnavailableRanges(widget.rentalAdId);
    });
  }

  Future<void> _addUnavailablePeriod() async {
    final now = DateTime.now();
    final startDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      helpText: 'اختر بداية فترة عدم التوفر',
    );
    if (startDate == null || !mounted) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: startDate.add(const Duration(days: 365)),
      helpText: 'اختر نهاية فترة عدم التوفر',
    );
    if (endDate == null || !mounted) return;

    final reason = await _askReason();
    if (!mounted) return;

    try {
      await _rentalAdService.addUnavailableDates(
        rentalAdId: widget.rentalAdId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تم حجب هذه الفترة بنجاح');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, title: 'تعذّر حجب الفترة', debugMessage: e);
    }
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب عدم التوفر (اختياري)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'مثال: صيانة دورية'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('تخطي'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeRange(Map<String, dynamic> range) async {
    final id = range['id'];
    if (id == null) return; // لا يمكن حذف نطاق مصدره حجز فعلي (booking)

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الحجب'),
        content: const Text('هل تريد إعادة فتح هذه الفترة للحجز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _rentalAdService.removeUnavailableDates(
        rentalAdId: widget.rentalAdId,
        unavailabilityId: id as int,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تمت إعادة فتح الفترة للحجز');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, title: 'تعذّر إلغاء الحجب', debugMessage: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'أيام عدم التوفر',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUnavailablePeriod,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.event_busy, color: Colors.white),
        label: const Text('حجب فترة', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          if (widget.carTitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.carTitle!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'حدّد الأيام التي تريد أن تبقى فيها السيارة غير متاحة للحجز، '
                'إضافة إلى الأيام المحجوزة فعلياً عبر التطبيق.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _rangesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SkeletonList(itemCount: 5);
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('تعذّر تحميل البيانات')),
                      ],
                    );
                  }
                  final ranges = snapshot.data ?? [];
                  if (ranges.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'لا توجد أيام محجوبة، السيارة متاحة بالكامل',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: ranges.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final range = ranges[index];
                      final isBooking = range['source'] == 'booking';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isBooking
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isBooking ? Icons.event_available : Icons.block,
                              color: isBooking ? AppColors.primary : Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${range['start_date']}  →  ${range['end_date']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isBooking
                                        ? 'محجوزة فعلياً عبر التطبيق'
                                        : (range['reason']?.toString().isNotEmpty == true
                                            ? range['reason'].toString()
                                            : 'محجوبة يدوياً من قبلك'),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (!isBooking)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                onPressed: () => _removeRange(range),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
