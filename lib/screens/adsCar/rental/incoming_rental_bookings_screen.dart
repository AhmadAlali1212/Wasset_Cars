import 'package:flutter/material.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/rental_booking_model.dart';
import 'package:mators_car/services/controllers/rental_booking_service.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/ulits/constant.dart';
import 'package:mators_car/screens/disputes/raise_dispute_screen.dart';

/// شاشة "الطلبات الواردة" لمالك إعلانات التأجير — تسدّ الفجوة التي كانت
/// تمنعه من رؤية من حجز سيارته إطلاقاً، وتتيح له تأكيد التسليم والإرجاع
/// الفعليين (بدل الاعتماد الكامل على تنسيق خارج التطبيق).
class IncomingRentalBookingsScreen extends StatefulWidget {
  const IncomingRentalBookingsScreen({super.key});

  @override
  State<IncomingRentalBookingsScreen> createState() =>
      _IncomingRentalBookingsScreenState();
}

class _IncomingRentalBookingsScreenState
    extends State<IncomingRentalBookingsScreen> {
  final RentalBookingService _bookingService = RentalBookingService();
  late Future<List<RentalBooking>> _bookingsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _bookingsFuture = _loadBookings();
  }

  Future<List<RentalBooking>> _loadBookings() async {
    final list = await _bookingService.getIncomingBookings();
    return list.map((json) => RentalBooking.fromJson(json)).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  Future<void> _refresh() async {
    setState(_load);
    await _bookingsFuture;
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: successMessage);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر تنفيذ العملية',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
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
          'الطلبات الواردة',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<RentalBooking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 5);
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'تعذر جلب الطلبات\n'
                      '${ApiException.userMessage(snapshot.error)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد طلبات حجز على إعلاناتك بعد')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = bookings[index];
                return _IncomingBookingCard(
                  booking: b,
                  busy: _busy,
                  onApprove:
                      () => _runAction(
                        () => _bookingService.approveBooking(b.id),
                        'تمت الموافقة على الحجز',
                      ),
                  onReject:
                      () => _runAction(
                        () => _bookingService.rejectBooking(b.id),
                        'تم رفض الحجز',
                      ),
                  onMarkDelivered:
                      () => _runAction(
                        () => _bookingService.markDelivered(b.id),
                        'تم تأكيد التسليم',
                      ),
                  onMarkReturned:
                      () => _runAction(
                        () => _bookingService.markReturned(b.id),
                        'تم تأكيد الإرجاع',
                      ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _IncomingBookingCard extends StatelessWidget {
  final RentalBooking booking;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onMarkDelivered;
  final VoidCallback onMarkReturned;

  const _IncomingBookingCard({
    required this.booking,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onMarkDelivered,
    required this.onMarkReturned,
  });

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ad = booking.rentalAd;
    final car = ad?.car;
    final imageUrl = AppConstants.resolveImageUrl(
      car != null && car.images.isNotEmpty ? car.images.first : null,
    );
    final title =
        car != null && car.make.isNotEmpty
            ? '${car.make} ${car.model} ${car.year}'
            : 'حجز #${booking.id}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    imageUrl != null
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                        )
                        : Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.renterName?.isNotEmpty == true
                          ? 'المستأجر: ${booking.renterName}'
                          : 'المستأجر: #${booking.renterId ?? '-'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    if ((booking.renterPhone ?? '').isNotEmpty)
                      Text(
                        booking.renterPhone!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (booking.status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'موافقة',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (booking.status == 'confirmed') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        busy || booking.deliveredAt != null
                            ? null
                            : onMarkDelivered,
                    icon: Icon(
                      booking.deliveredAt != null
                          ? Icons.check_circle
                          : Icons.local_shipping_outlined,
                      size: 16,
                    ),
                    label: Text(
                      booking.deliveredAt != null
                          ? 'تم التسليم'
                          : 'تأكيد التسليم',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        busy ||
                                booking.deliveredAt == null ||
                                booking.returnedAt != null
                            ? null
                            : onMarkReturned,
                    icon: Icon(
                      booking.returnedAt != null
                          ? Icons.check_circle
                          : Icons.assignment_return_outlined,
                      size: 16,
                    ),
                    label: Text(
                      booking.returnedAt != null
                          ? 'تم الإرجاع'
                          : 'تأكيد الإرجاع',
                    ),
                  ),
                ),
              ],
            ),
            // ⬅️ جديد: إبلاغ المالك عن مشكلة (مثلاً المستأجر لم يُرجع
            // السيارة بالموعد) — متاح طالما الحجز جارٍ (confirmed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RaiseDisputeScreen(
                            againstUserId: booking.renterId ?? 0,
                            againstUserName:
                                booking.renterName?.isNotEmpty == true
                                    ? booking.renterName!
                                    : 'المستأجر',
                            transactionType: 'rental_booking',
                            transactionId: booking.id,
                            transactionTitle: title,
                          ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.report_problem_outlined,
                  size: 16,
                  color: Colors.orange,
                ),
                label: const Text(
                  'لدي مشكلة',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          ] else
            Text(
              booking.status == 'completed'
                  ? 'اكتملت هذه الفترة'
                  : 'لا يوجد إجراء متاح حالياً',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
