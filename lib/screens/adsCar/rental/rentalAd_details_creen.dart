import 'package:flutter/material.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/ulits/contact_launcher.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/services/controllers/rental_ad_service.dart';
import 'package:mators_car/services/controllers/rental_booking_service.dart';
import 'package:mators_car/services/controllers/favorite_service.dart';
import 'package:mators_car/screens/adsCar/rental/my_rental_bookings_screen.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_map_screen.dart';
import 'package:mators_car/screens/company/company_public_profile_screen.dart';
import 'package:mators_car/screens/messages/chat_thread_screen.dart';
import 'package:mators_car/widgets/rental/rental_ads/rental_ad_detail_widgets.dart';
import '../../../widgets/auction/car_image_slider.dart';
import '../../../widgets/section_header.dart';

class RentalAdDetailScreen extends StatefulWidget {
  final Ad ad;
  const RentalAdDetailScreen({super.key, required this.ad});

  @override
  State<RentalAdDetailScreen> createState() => _RentalAdDetailScreenState();
}

class _RentalAdDetailScreenState extends State<RentalAdDetailScreen> {
  final RentalAdService _rentalAdService = RentalAdService();
  final RentalBookingService _bookingService = RentalBookingService();
  final FavoriteService _favoriteService = FavoriteService();
  bool _isFavorite = false;
  bool _isFavoriteBusy = false;
  bool _isBooking = false;
  // الفترات غير المتاحة (حجوزات مؤكدة + أيام حجبها المالك يدوياً)، تُستخدم
  // لتعطيلها في تقويم اختيار تاريخ الحجز بدل تركها لتفشل فقط بعد الإرسال.
  List<DateTimeRange> _unavailableRanges = [];
  bool _loadingAvailability = true;
  late Ad _ad;

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
    _refreshAdDetails();
    _loadFavoriteStatus();
    _loadAvailability();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFav = await _favoriteService.isFavorite(_ad.carId);
      if (!mounted) return;
      setState(() => _isFavorite = isFav);
    } catch (_) {
      // تجاهل بصمت: لا نريد كسر الشاشة إذا فشل هذا الطلب الثانوي فقط
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteBusy) return;
    setState(() => _isFavoriteBusy = true);
    final wasFavorite = _isFavorite;
    try {
      if (wasFavorite) {
        await _favoriteService.removeFavorite(_ad.carId);
      } else {
        await _favoriteService.addFavorite(_ad.carId);
      }
      if (!mounted) return;
      setState(() => _isFavorite = !wasFavorite);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر تحديث المفضلة',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isFavoriteBusy = false);
    }
  }

  // جلب الأيام غير المتاحة من الخادم (حجوزات مؤكدة + حجب يدوي من المالك)
  Future<void> _loadAvailability() async {
    try {
      final ranges = await _rentalAdService.getUnavailableRanges(_ad.id);
      if (!mounted) return;
      setState(() {
        _unavailableRanges =
            ranges.map((r) {
              final start = DateTime.parse(r['start_date'] as String);
              final end = DateTime.parse(r['end_date'] as String);
              return DateTimeRange(start: start, end: end);
            }).toList();
        _loadingAvailability = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAvailability = false);
    }
  }

  bool _isDateBlocked(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    for (final range in _unavailableRanges) {
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(range.end.year, range.end.month, range.end.day);
      if (!d.isBefore(start) && !d.isAfter(end)) return true;
    }
    return false;
  }

  bool _rangeOverlapsBlocked(DateTime start, DateTime end) {
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (_isDateBlocked(d)) return true;
    }
    return false;
  }

  // إعادة جلب أحدث بيانات إعلان التأجير من الخادم عبر GET /rental-ads/{id}
  Future<void> _refreshAdDetails() async {
    try {
      final fresh = await _rentalAdService.getRentalAdDetails(_ad.id);
      if (!mounted || fresh.isEmpty) return;
      final freshAd = Ad.fromJson(fresh);
      // GET /rental-ads/{id} لا يُرجع كائن السيارة المتداخل إطلاقاً (بعكس
      // القائمة العامة index())، فلو اعتمدنا عليه مباشرة كانت كل بيانات
      // السيارة (الصور/الموديل/الموقع...) تختفي فجأة بعد أول تحديث.
      // لذلك نحافظ على بيانات السيارة التي وصلتنا أصلاً من شاشة القائمة
      // إن كانت الاستجابة الجديدة لا تحوي سيارة صالحة.
      setState(() {
        _ad = freshAd.car.id != 0 ? freshAd : freshAd.withCar(_ad.car);
      });
    } catch (_) {
      // في حال فشل التحديث نكتفي بعرض البيانات المتوفرة مسبقاً من القائمة
    }
  }

  // اختيار تاريخ البداية والنهاية ثم إرسال طلب الحجز فعلياً عبر RentalBookingService
  // الأيام التي حددها المالك كغير متاحة (أو محجوزة فعلياً) تظهر معطّلة
  // (غير قابلة للاختيار) مباشرة في التقويم، بدل اكتشاف التعارض بعد الإرسال.
  Future<void> _showBookingDialog() async {
    if (_loadingAvailability) {
      AppSnackbar.showError(
        context,
        title: 'جاري تحميل أيام التوفر، حاول بعد لحظات',
      );
      return;
    }

    final now = DateTime.now();
    final startDate = await showDatePicker(
      context: context,
      initialDate: _firstAvailableDayFrom(now.add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'اختر تاريخ بداية التأجير (الأيام المظللة غير متاحة)',
      selectableDayPredicate: (day) => !_isDateBlocked(day),
    );
    if (startDate == null || !mounted) return;

    final minEnd = startDate.add(const Duration(days: 1));
    final endDate = await showDatePicker(
      context: context,
      initialDate: _firstAvailableDayFrom(minEnd, stopAt: startDate),
      firstDate: minEnd,
      lastDate: startDate.add(const Duration(days: 365)),
      helpText: 'اختر تاريخ نهاية التأجير (الأيام المظللة غير متاحة)',
      // نمنع اختيار أي تاريخ نهاية يجعل الفترة الكاملة تتقاطع مع يوم محجوب
      selectableDayPredicate: (day) => !_rangeOverlapsBlocked(startDate, day),
    );
    if (endDate == null || !mounted) return;

    if (_rangeOverlapsBlocked(startDate, endDate)) {
      AppSnackbar.showError(
        context,
        title: 'الفترة المختارة تتضمن أياماً غير متاحة، اختر فترة أخرى',
      );
      return;
    }

    await _submitBooking(startDate, endDate);
  }

  // أول يوم متاح ابتداءً من تاريخ معيّن (لتفادي فتح التقويم على يوم محجوب)
  DateTime _firstAvailableDayFrom(DateTime from, {DateTime? stopAt}) {
    var d = from;
    var guard = 0;
    while (_isDateBlocked(d) && guard < 400) {
      d = d.add(const Duration(days: 1));
      guard++;
    }
    return d;
  }

  Future<void> _submitBooking(DateTime startDate, DateTime endDate) async {
    setState(() => _isBooking = true);
    try {
      await _bookingService.createBooking(
        rentalAdId: _ad.id,
        startDate: startDate,
        endDate: endDate,
      );
      if (!mounted) return;
      await _loadAvailability(); // تحديث الأيام المتاحة فوراً بعد الحجز الجديد
      if (!mounted) return;
      // مجرد Snackbar لا يكفي لإقناع المستخدم أن الحجز فعلاً تسجّل، خصوصاً
      // أن هذه الشاشة نفسها لا تعرض أي حالة "محجوز" بعدها. لذلك نأخذه
      // مباشرة لشاشة "حجوزاتي" ليرى حجزه الجديد ضمن القائمة كتأكيد ملموس.
      AppSnackbar.showSuccess(context, title: 'تم إرسال طلب الحجز بنجاح');
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyRentalBookingsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر إرسال طلب الحجز',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'تفاصيل التأجير',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              AppSnackbar.showSuccess(
                context,
                title: 'تم تجهيز رابط التأجير للمشاركة',
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: _isFavoriteBusy ? null : _toggleFavorite,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CarImageSlider(images: _ad.car.images),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_ad.car.make} ${_ad.car.model} ${_ad.car.year}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // أزرار عرض السعر المزدوجة المتطابقة مع الصورة تماماً
                      RentalPriceRow(
                        dailyPrice: _ad.dailyPrice,
                        monthlyPrice: _ad.monthlyPrice,
                      ),
                      const SizedBox(height: 20),

                      // شبكة الخصائص الثمانية الكاملة للتأجير من الصورة الثالثة
                      RentalEightSpecsGrid(ad: _ad),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'شروط التأجير'),
                      const SizedBox(height: 10),
                      const RentalConditionsChecklist(),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'المميزات'),
                      const SizedBox(height: 10),
                      const RentalFeatureChips(),
                      const SizedBox(height: 24),

                      // كارت معلومات المالك مع خريطة مصغرة لموقع استلام السيارة
                      const SectionHeader(
                        title: 'معلومات المؤجر وموقع الاستلام',
                      ),
                      const SizedBox(height: 12),
                      RentalOwnerAndMapCard(
                        ad: _ad,
                        onTapOwner: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CompanyPublicProfileScreen(
                                    company: {
                                      'id': _ad.userId,
                                      'name': _ad.contactName,
                                      'phone': _ad.contactPhone,
                                    },
                                  ),
                            ),
                          );
                        },
                        onTapMap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdMapScreen(ad: _ad),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // كتل أزرار الاتصال والحجز السفلي الذكي والتفاعلي
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RentalDetailsBottomActionBar(
              isBooking: _isBooking,
              onMessage: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChatThreadScreen(
                          partnerId: widget.ad.userId,
                          partnerName:
                              widget.ad.contactName.isNotEmpty
                                  ? widget.ad.contactName
                                  : 'مستخدم Syria Motor',
                        ),
                  ),
                );
              },
              onWhatsapp:
                  () => ContactLauncher.whatsapp(
                    context,
                    widget.ad.contactPhone,
                    message:
                        'مرحباً، أنا مهتم بإعلان تأجير ${widget.ad.car.make} '
                        '${widget.ad.car.model} ${widget.ad.car.year} على تطبيق Syria Motor.',
                  ),
              onCall:
                  () => ContactLauncher.call(context, widget.ad.contactPhone),
              onBookNow: _showBookingDialog,
            ),
          ),
        ],
      ),
    );
  }
}
