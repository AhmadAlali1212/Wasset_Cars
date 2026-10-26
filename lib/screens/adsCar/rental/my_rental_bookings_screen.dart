import 'package:flutter/material.dart';
import 'package:mators_car/data/models/rental_booking_model.dart';
import 'package:mators_car/services/controllers/rental_booking_service.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/rental/rental_booking_widgets.dart';

// شاشة "حجوزات التأجير الخاصة بي" (بصفة المستأجر).
// حالة التسليم والإرجاع تأتي من الخادم، وتؤكّد من طرف مالك الإعلان.
class MyRentalBookingsScreen extends StatefulWidget {
  const MyRentalBookingsScreen({super.key});

  @override
  State<MyRentalBookingsScreen> createState() => _MyRentalBookingsScreenState();
}

class _MyRentalBookingsScreenState extends State<MyRentalBookingsScreen> {
  final RentalBookingService _bookingService = RentalBookingService();
  late Future<List<RentalBooking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _bookingsFuture = _loadBookings();
  }

  Future<List<RentalBooking>> _loadBookings() async {
    final list = await _bookingService.getMyBookings();
    return list.map((json) => RentalBooking.fromJson(json)).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  Future<void> _refresh() async {
    setState(_load);
    await _bookingsFuture;
  }

  Future<void> _cancelBooking(RentalBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('إلغاء الحجز'),
            content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('تراجع'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'إلغاء الحجز',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _bookingService.cancelBooking(booking.id);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تم إلغاء الحجز بنجاح');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر إلغاء الحجز',
        debugMessage: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'حجوزات التأجير',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: RentalBookingsContent(
          bookingsFuture: _bookingsFuture,
          onCancel: _cancelBooking,
        ),
      ),
    );
  }
}
