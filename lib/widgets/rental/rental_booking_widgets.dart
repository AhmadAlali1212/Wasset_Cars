import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mators_car/data/models/rental_booking_model.dart';
import 'package:mators_car/screens/disputes/raise_dispute_screen.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constant.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';

class RentalBookingsContent extends StatelessWidget {
  final Future<List<RentalBooking>> bookingsFuture;
  final Future<void> Function(RentalBooking booking) onCancel;

  const RentalBookingsContent({
    super.key,
    required this.bookingsFuture,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RentalBooking>>(
      future: bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonList(itemCount: 5);
        }
        if (snapshot.hasError) {
          return _BookingsErrorState(error: snapshot.error);
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) return const _EmptyBookingsState();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return RentalBookingCard(
              booking: booking,
              onCancel: () => onCancel(booking),
            );
          },
        );
      },
    );
  }
}

class _BookingsErrorState extends StatelessWidget {
  final Object? error;

  const _BookingsErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Text(
            'تعذر جلب حجوزاتك\n${ApiException.userMessage(error)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Icon(Icons.event_busy_outlined, size: 56, color: Colors.black26),
        SizedBox(height: 12),
        Center(child: Text('لا توجد حجوزات تأجير بعد')),
      ],
    );
  }
}

class RentalBookingCard extends StatelessWidget {
  final RentalBooking booking;
  final VoidCallback onCancel;

  const RentalBookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
  });

  Color _statusColor() {
    if (booking.status == 'cancelled' || booking.status == 'rejected') {
      return Colors.red;
    }
    if (booking.status == 'completed' || booking.hasEnded) return Colors.grey;
    if (booking.status == 'pending') return Colors.orange;
    if (booking.hasStarted) return Colors.green;
    return Colors.orange;
  }

  String _statusLabel() {
    switch (booking.status) {
      case 'cancelled':
        return 'ملغى';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
        return 'بانتظار موافقة المالك';
      case 'completed':
        return 'مكتمل';
    }
    if (booking.hasEnded) return 'منتهٍ';
    if (booking.hasStarted) return 'جارٍ الآن';
    return 'قادم';
  }

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
            : 'حجز تأجير #${booking.id}';
    final isInactive =
        booking.status == 'cancelled' || booking.status == 'rejected';
    final statusColor = _statusColor();

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
          _BookingSummary(
            booking: booking,
            imageUrl: imageUrl,
            title: title,
            statusColor: statusColor,
            statusLabel: _statusLabel(),
          ),
          if (!isInactive) ...[
            const Divider(height: 22),
            _BookingProgress(booking: booking),
            if (booking.status != 'completed') ...[
              const SizedBox(height: 8),
              _BookingActions(
                booking: booking,
                adTitle: title,
                onCancel: onCancel,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  final RentalBooking booking;
  final String? imageUrl;
  final String title;
  final Color statusColor;
  final String statusLabel;

  const _BookingSummary({
    required this.booking,
    required this.imageUrl,
    required this.title,
    required this.statusColor,
    required this.statusLabel,
  });

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CarImage(imageUrl: imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _BookingStatus(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}'
                '  (${booking.durationDays > 0 ? booking.durationDays : 1} يوم)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              if (booking.totalPrice.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'الإجمالي: ${booking.totalPrice} ل.س',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (booking.status == 'rejected' &&
                  (booking.rejectionReason ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'سبب الرفض: ${booking.rejectionReason}',
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarImage extends StatelessWidget {
  final String? imageUrl;

  const _CarImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 64,
      height: 64,
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.directions_car, color: Colors.grey),
    );
    if (imageUrl == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        memCacheWidth: 128,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _BookingStatus extends StatelessWidget {
  final String label;
  final Color color;

  const _BookingStatus({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BookingProgress extends StatelessWidget {
  final RentalBooking booking;

  const _BookingProgress({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusChip(
                label: 'تم التسليم',
                active: booking.deliveredAt != null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatusChip(
                label: 'تم الإرجاع',
                active: booking.returnedAt != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'يؤكّد هذه الحالة صاحب السيارة، وتظهر هنا فور تأكيدها.',
          style: TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}

class _BookingActions extends StatelessWidget {
  final RentalBooking booking;
  final String adTitle;
  final VoidCallback onCancel;

  const _BookingActions({
    required this.booking,
    required this.adTitle,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final ad = booking.rentalAd;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed:
              ad == null
                  ? null
                  : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RaiseDisputeScreen(
                            againstUserId: ad.userId,
                            againstUserName:
                                ad.contactName.isNotEmpty
                                    ? ad.contactName
                                    : 'المالك',
                            transactionType: 'rental_booking',
                            transactionId: booking.id,
                            transactionTitle: adTitle,
                          ),
                    ),
                  ),
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
        TextButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close, size: 16, color: Colors.red),
          label: const Text('إلغاء الحجز', style: TextStyle(color: Colors.red)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            active ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? Colors.green : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: active ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.green.shade800 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
