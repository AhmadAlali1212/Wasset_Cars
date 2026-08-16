import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mators_car/models/rental_booking_model.dart';
import 'package:mators_car/services/rental_booking_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constans.dart';

// شاشة "حجوزات التأجير الخاصة بي" — كانت غير مبنية إطلاقاً رغم أن
// RentalBookingService.getMyBookings()/cancelBooking() جاهزتان بالكامل.
//
// ملاحظة مهمة بخصوص تأكيد الاستلام/التسليم:
// لا يوفّر الـ API الحالي أي حقل أو endpoint لتأكيد استلام/تسليم السيارة
// فعلياً (لا للمستأجر ولا لصاحب الإعلان)، ولا حتى endpoint يتيح لصاحب
// إعلان التأجير رؤية من قام بحجز سيارته. لذلك:
// - تأكيد "تم الاستلام" و"تم الإرجاع" هنا هو تتبّع شخصي محلي على جهاز
//   المستأجر فقط (مخزّن عبر SharedPreferences)، ولا يصل لصاحب السيارة
//   ولا يُغيّر أي حالة على السيرفر — تم توضيح هذا صراحة بالواجهة.
// - لإتمام هذه الميزة فعلياً يلزم إضافة endpoint من طرف الباك-إند
//   (مثال: PATCH /rental-bookings/{id}/status أو ما شابه).
class MyRentalBookingsScreen extends StatefulWidget {
  const MyRentalBookingsScreen({super.key});

  @override
  State<MyRentalBookingsScreen> createState() =>
      _MyRentalBookingsScreenState();
}

class _MyRentalBookingsScreenState extends State<MyRentalBookingsScreen> {
  final RentalBookingService _bookingService = RentalBookingService();
  late Future<List<RentalBooking>> _bookingsFuture;

  // {bookingId: {'received': bool, 'returned': bool}} — مخزّنة محلياً فقط
  Map<int, Map<String, bool>> _localStatus = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _bookingsFuture = _loadBookings();
  }

  Future<List<RentalBooking>> _loadBookings() async {
    await _loadLocalStatus();
    final list = await _bookingService.getMyBookings();
    return list.map((json) => RentalBooking.fromJson(json)).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  static const _prefix = 'booking_status_';

  // يقرأ كل مفاتيح التتبع المحلي دفعة واحدة، ويحلل كل مفتاح على شكل
  // "booking_status_<id>_received" أو "booking_status_<id>_returned"
  Future<void> _loadLocalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <int, Map<String, bool>>{};
    for (final key in keys) {
      final rest = key.substring(_prefix.length); // "<id>_received" أو "<id>_returned"
      String? flag;
      String? idPart;
      if (rest.endsWith('_received')) {
        flag = 'received';
        idPart = rest.substring(0, rest.length - '_received'.length);
      } else if (rest.endsWith('_returned')) {
        flag = 'returned';
        idPart = rest.substring(0, rest.length - '_returned'.length);
      }
      final id = idPart != null ? int.tryParse(idPart) : null;
      if (id == null || flag == null) continue;
      final value = prefs.getBool(key) ?? false;
      map.putIfAbsent(id, () => {'received': false, 'returned': false});
      map[id]![flag] = value;
    }
    if (!mounted) return;
    setState(() => _localStatus = map);
  }

  Future<void> _setFlag(int bookingId, String flag, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${bookingId}_$flag', value);
    if (!mounted) return;
    setState(() {
      _localStatus[bookingId] = {
        ..._localStatus[bookingId] ?? {'received': false, 'returned': false},
        flag: value,
      };
    });
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
                child: const Text('إلغاء الحجز', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _bookingService.cancelBooking(booking.id);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحجز بنجاح')),
      );
      _refresh();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('تعذر إلغاء الحجز: $e')),
      );
    }
  }

  // مربّع توضيحي عند أول ضغط على "تم الاستلام"/"تم الإرجاع" يشرح أن هذا
  // تتبّع شخصي محلي فقط، حتى لا يظن المستخدم أن صاحب السيارة سيُبلَّغ تلقائياً
  Future<bool> _confirmLocalTracking(String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(action),
            content: const Text(
              'هذا التأكيد لتتبعك الشخصي داخل التطبيق فقط، ولا يصل لصاحب '
              'السيارة تلقائياً حالياً. للتواصل بخصوص الاستلام أو الإرجاع '
              'الفعلي يُرجى التنسيق المباشر مع صاحب الإعلان.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('فهمت، تأكيد'),
              ),
            ],
          ),
    );
    return confirmed == true;
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
        child: FutureBuilder<List<RentalBooking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'تعذر جلب حجوزاتك\n${snapshot.error}',
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
                  Icon(Icons.event_busy_outlined, size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد حجوزات تأجير بعد')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final localFlags =
                    _localStatus[booking.id] ??
                    {'received': false, 'returned': false};
                return _BookingCard(
                  booking: booking,
                  received: localFlags['received'] ?? false,
                  returned: localFlags['returned'] ?? false,
                  onCancel: () => _cancelBooking(booking),
                  onToggleReceived: (value) async {
                    if (value) {
                      final ok = await _confirmLocalTracking('تأكيد الاستلام');
                      if (!ok) return;
                    }
                    await _setFlag(booking.id, 'received', value);
                  },
                  onToggleReturned: (value) async {
                    if (value) {
                      final ok = await _confirmLocalTracking('تأكيد الإرجاع');
                      if (!ok) return;
                    }
                    await _setFlag(booking.id, 'returned', value);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final RentalBooking booking;
  final bool received;
  final bool returned;
  final VoidCallback onCancel;
  final ValueChanged<bool> onToggleReceived;
  final ValueChanged<bool> onToggleReturned;

  const _BookingCard({
    required this.booking,
    required this.received,
    required this.returned,
    required this.onCancel,
    required this.onToggleReceived,
    required this.onToggleReturned,
  });

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Color _statusColor() {
    if (booking.status.toLowerCase().contains('cancel')) return Colors.red;
    if (booking.hasEnded) return Colors.grey;
    if (booking.hasStarted) return Colors.green;
    return Colors.orange;
  }

  String _statusLabel() {
    if (booking.status.toLowerCase().contains('cancel')) return 'ملغى';
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
    final isCancelled = booking.status.toLowerCase().contains('cancel');

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
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          memCacheWidth: 128,
                          placeholder:
                              (_, __) => Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFFF0F0F0),
                              ),
                          errorWidget:
                              (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.directions_car, color: Colors.grey),
                              ),
                        )
                        : Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.directions_car, color: Colors.grey),
                        ),
              ),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                  ],
                ),
              ),
            ],
          ),
          if (!isCancelled) ...[
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: _TrackingCheckTile(
                    label: 'تم الاستلام',
                    value: received,
                    onChanged: onToggleReceived,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TrackingCheckTile(
                    label: 'تم الإرجاع',
                    value: returned,
                    onChanged: onToggleReturned,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: const Text('إلغاء الحجز', style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingCheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TrackingCheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: value ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: value ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value ? Colors.green.shade800 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
