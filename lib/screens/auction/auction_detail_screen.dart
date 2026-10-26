import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/services/controllers/auction_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/screens/company/company_wallet_screen.dart';
import 'package:mators_car/screens/individual/individual_wallet_screen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/section_header.dart';
import 'package:mators_car/widgets/autction/auction_detail_widgets.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Auction auction;

  const AuctionDetailScreen({super.key, required this.auction});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

// المرحلة التي وصلها المزاد من ناحية دورة حياته بعد الإغلاق، تُستخدم لتحديد
// أي أزرار/رسائل تظهر لكل من البائع والفائز وبقية الزوار.
enum _AuctionPhase {
  pendingApproval, // قيد المراجعة الإدارية قبل النشاط
  bidding, // نشط والمزايدة مفتوحة
  timeUpAwaitingClose, // انتهى الوقت بالعدّاد لكن حالة السيرفر لم تتحول بعد
  closedNoWinner, // أُغلق المزاد لكن بلا فائز (winner_id فارغ — عادة لعدم وجود مزايدات كافية أو لأن خدمة الإغلاق لم تُحدّد فائزاً بعد)
  awaitingSellerDecision, // انتهى المزاد فعلياً (حالة السيرفر) وبانتظار قرار البائع
  awaitingSaleCompletion, // البائع قبل السعر، بانتظار تأكيد إتمام البيع
  completed, // تم تأكيد إتمام البيع فعلياً
  rejected, // البائع رفض السعر النهائي
  withdrawn, // الفائز تراجع عن الصفقة (صودر عربونه)
  cancelled, // المزاد أُلغي
  unknown,
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _bidController = TextEditingController();
  final AuctionService _auctionService = AuctionService();
  late Auction _auction = widget.auction;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  bool _isSubmittingBid = false;

  int? _myUserId;
  bool _isOwner = false;
  bool _isWinner = false;
  bool _isProcessingAction = false;
  bool _isRefreshingStatus = false;

  // قرار محلي بالجلسة يُحدَّث فوراً بعد نجاح أي إجراء (قبول/رفض/تأكيد/تراجع)
  // بحيث تنتقل الواجهة للمرحلة التالية مباشرة دون انتظار شكل استجابة محدد
  // من السيرفر لحقل حالة قد يختلف اسمه. القيمة الابتدائية تُشتق من status.
  _AuctionPhase? _localPhaseOverride;

  // تحديث دوري تلقائي بانتظار قرار الطرف الآخر (بائع أو فائز)، حتى لا
  // يعتمد المستخدم فقط على تذكّر الضغط على زر "تحديث" يدوياً.
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // نجلب أحدث حالة للمزاد فور فتح الشاشة بدل الاكتفاء بالبيانات القادمة
    // من شاشة القائمة، والتي قد تكون قديمة (خصوصاً حالة "closed/active")
    _refreshAuction();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      // لا داعي للاستمرار بالاستطلاع بعد اكتمال الصفقة أو انتهائها فعلياً
      if (![
        _AuctionPhase.completed,
        _AuctionPhase.rejected,
        _AuctionPhase.withdrawn,
        _AuctionPhase.cancelled,
      ].contains(_phase)) {
        _refreshAuction();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthStorage.getUser();
    final id = int.tryParse('${user?['id']}');
    if (!mounted) return;
    setState(() {
      _myUserId = id;
      _isOwner = id != null && id == _auction.car.userId;
      _isWinner =
          id != null && _auction.winnerId != null && id == _auction.winnerId;
    });
  }

  // يشتق مرحلة المزاد الحالية من نص status القادم من السيرفر باستخدام
  // مطابقة مرنة (contains) لتغطية تسميات محتملة مختلفة، ما لم يوجد قرار
  // محلي أحدث تم تعيينه بعد إجراء ناجح بهذه الجلسة.
  _AuctionPhase get _phase {
    if (_localPhaseOverride != null) return _localPhaseOverride!;

    final s = _auction.status.toLowerCase();

    if (s.contains('cancel')) return _AuctionPhase.cancelled;
    if (s.contains('pending') || s.contains('review') || s.contains('draft')) {
      return _AuctionPhase.pendingApproval;
    }

    // نطابق هنا بالضبط شروط AuctionController::acceptFinalPrice/
    // rejectFinalPrice الفعلية بالباك-إند:
    // status !== 'closed' || !winner_id  => لا يمكن قبول/رفض السعر
    // final_price_status !== 'pending'   => تم اتخاذ القرار مسبقاً
    if (s.contains('closed')) {
      // تراجع الفائز أو تأكيد إتمام البيع أدق مؤشر لأنهما يُسجَّلان
      // بتاريخ فعلي بعد أن يصبح final_price_status = accepted
      if (_auction.winnerWithdrewAt != null) return _AuctionPhase.withdrawn;
      if (_auction.settlementCompletedAt != null)
        return _AuctionPhase.completed;

      final decision = _auction.finalPriceStatus?.toLowerCase();
      if (decision != null && decision != 'pending') {
        if (decision.contains('reject')) return _AuctionPhase.rejected;
        if (decision.contains('accept')) {
          return _AuctionPhase.awaitingSaleCompletion;
        }
      }

      // بدون فائز لا يقبل السيرفر أي قرار إطلاقاً (نفس رسالة الخطأ
      // "لا يمكن قبول السعر قبل إغلاق المزاد وتحديد الفائز")، فلا نعرض
      // زرّي القبول/الرفض في هذه الحالة لتفادي محاولة فاشلة أكيدة.
      if (_auction.winnerId == null) return _AuctionPhase.closedNoWinner;

      return _AuctionPhase.awaitingSellerDecision;
    }

    if (s.contains('active')) {
      final isTimeUp = !_auction.endTime.isAfter(DateTime.now());
      return isTimeUp
          ? _AuctionPhase.timeUpAwaitingClose
          : _AuctionPhase.bidding;
    }
    return _AuctionPhase.unknown;
  }

  // نعرض شارة "أنت الفائز" فقط بعد أن يُحدَّد فائز فعلياً من السيرفر (أي
  // بمراحل ما بعد الإغلاق)، وليس أثناء المزايدة أو إذا لم يُحدَّد فائز بعد
  bool get _showWinnerBadge => const [
    _AuctionPhase.awaitingSellerDecision,
    _AuctionPhase.awaitingSaleCompletion,
    _AuctionPhase.completed,
    _AuctionPhase.rejected,
    _AuctionPhase.withdrawn,
  ].contains(_phase);

  String get _winnerBadgeSubtitle {
    switch (_phase) {
      case _AuctionPhase.awaitingSellerDecision:
        return 'بانتظار قرار البائع بشأن السعر النهائي.';
      case _AuctionPhase.awaitingSaleCompletion:
        return 'وافق البائع على السعر، بانتظار إتمام البيع بينكما خارج التطبيق.';
      case _AuctionPhase.completed:
        return 'تم إتمام عملية البيع بنجاح.';
      case _AuctionPhase.rejected:
        return 'مع الأسف رفض البائع السعر النهائي، وأُعيد عربونك إلى محفظتك.';
      case _AuctionPhase.withdrawn:
        return 'تراجعت عن هذه الصفقة، وصودر عربونك لصالح البائع.';
      default:
        return '';
    }
  }

  // العنوان والألوان تتغير حسب النتيجة النهائية؛ "مبروك" مناسبة فقط طالما
  // الصفقة قائمة أو تمت بنجاح، أما بعد الرفض/التراجع فالنبرة يجب أن تعكس
  // ذلك بدل الاحتفاء بفوز لم يُتوَّج بصفقة فعلية.
  String get _winnerBadgeTitle {
    switch (_phase) {
      case _AuctionPhase.rejected:
      case _AuctionPhase.withdrawn:
        return 'كنت الفائز بهذا المزاد';
      default:
        return 'مبروك! أنت الفائز بهذا المزاد';
    }
  }

  List<Color> get _winnerBadgeColors {
    switch (_phase) {
      case _AuctionPhase.rejected:
      case _AuctionPhase.withdrawn:
        return const [Color(0xFF757575), Color(0xFF9E9E9E)];
      default:
        return const [Color(0xFF2E7D32), Color(0xFF4CAF50)];
    }
  }

  // شريط الإجراءات السفلي مبني كـ Positioned فوق محتوى الشاشة (وليس عبر
  // bottomNavigationBar الرسمي)، لذلك كان الـ SnackBar الافتراضي (behavior:
  // fixed) يرتسم خلفه عند أسفل الشاشة تماماً فيتداخل النصّان بصرياً ويبدو
  // النص مقطوعاً/متراكباً. الحل: SnackBar عائم (floating) بهامش سفلي كافٍ
  // ليظهر فوق شريط الإجراءات دائماً، مع شكل واضح ولفّ نص سليم.
  void _showSnackBar(String message, {required Color color}) {
    if (!mounted) return;
    if (color == Colors.red) {
      AppSnackbar.showError(context, title: message);
    } else if (color == Colors.green) {
      AppSnackbar.showSuccess(context, title: message);
    } else {
      AppSnackbar.showInfo(context, title: message);
    }
  }

  double _parsePrice(String price) {
    try {
      String cleanPrice = price
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .replaceAll('ل.س', '');
      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  String _formatPrice(double price) {
    String priceStr = price.toStringAsFixed(0);
    String formatted = '';
    int counter = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      counter++;
      formatted = priceStr[i] + formatted;
      if (counter % 3 == 0 && i != 0) formatted = ',$formatted';
    }
    return '$formatted ل.س';
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPriceValue = _parsePrice(_auction.currentPrice);
    final startingPriceValue = _parsePrice(_auction.startingPrice);
    final minBid = currentPriceValue * 1.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'تفاصيل المزاد',
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
              _showSnackBar(
                'تم نسخ رابط المزاد بنجاح!',
                color: AppColors.primary,
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معرض الصور مع شارة المزاد المباشر الهلامية ومؤشر الصفحات الرقمي
                Stack(
                  children: [
                    SizedBox(
                      height: 260,
                      child: PageView.builder(
                        itemCount: _auction.car.images.length,
                        onPageChanged:
                            (index) =>
                                setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: _auction.car.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            memCacheWidth: 900,
                            placeholder:
                                (context, url) => Container(
                                  height: 260,
                                  color: Colors.grey.shade200,
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 260,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.directions_car),
                                ),
                          );
                        },
                      ),
                    ),
                    Positioned(top: 16, right: 16, child: _buildLiveBadge()),
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${_auction.car.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // العنوان والموقع الفعلي
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // بدون Expanded هنا كان العنوان + الموقع يتجاوزان
                          // عرض السطر معاً عند كون الموقع نصاً طويلاً (مثال:
                          // "Boulder Creek، الولايات المتّحدة الأمريكيّة")،
                          // فيظهر تحذير RenderFlex overflow (الشرائط
                          // الصفراء/السوداء) بدل عرض نظيف — كما بالصورة.
                          Expanded(
                            child: Text(
                              '${_auction.car.make} ${_auction.car.model} ${_auction.car.year}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _auction.car.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // شارة "أنت الفائز" بارزة وثابتة (وليست فقط ضمن شريط
                      // الإجراءات السفلي) — تظهر بمجرد أن يحدد السيرفر فائزاً
                      // لهذا المزاد (winner_id) وكان المستخدم الحالي هو نفسه،
                      // في أي مرحلة لاحقة (بانتظار قرار البائع، بعد القبول،
                      // بعد الإتمام)، لتكون واضحة لا تحتاج تمرير للأسفل.
                      if (_isWinner && _showWinnerBadge)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _winnerBadgeColors,
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🏆',
                                  style: TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _winnerBadgeTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _winnerBadgeSubtitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // كارت الأسعار والعداد الزمني المدمج بالتصميم الجديد
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'ينتهي بعد',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatRemaining(
                                        _auction.endTime.difference(
                                          DateTime.now(),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 35,
                                  color: Colors.grey.shade200,
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'السعر الابتدائي',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatPrice(startingPriceValue),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 35,
                                  color: Colors.grey.shade200,
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'السعر الحالي',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatPrice(currentPriceValue),
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // العدادات الدائرية المصغرة المعروضة بالصورة
                            Builder(
                              builder: (context) {
                                final remaining = _auction.endTime.difference(
                                  DateTime.now(),
                                );
                                final isOver = remaining.isNegative;
                                final days = isOver ? 0 : remaining.inDays;
                                final hours =
                                    isOver
                                        ? 0
                                        : remaining.inHours.remainder(24);
                                final minutes =
                                    isOver
                                        ? 0
                                        : remaining.inMinutes.remainder(60);
                                final seconds =
                                    isOver
                                        ? 0
                                        : remaining.inSeconds.remainder(60);
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildTimeCircularUnit(
                                      seconds.toString().padLeft(2, '0'),
                                      'ثانية',
                                    ),
                                    _buildTimeCircularUnit(
                                      minutes.toString().padLeft(2, '0'),
                                      'دقيقة',
                                    ),
                                    _buildTimeCircularUnit(
                                      hours.toString().padLeft(2, '0'),
                                      'ساعة',
                                    ),
                                    _buildTimeCircularUnit(
                                      days.toString().padLeft(2, '0'),
                                      'يوم',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // المواصفات الأساسية الأربعة الموزعة شبكياً أسفل العداد
                      _buildAuctionGridSpecs(),
                      const SizedBox(height: 20),

                      const SectionHeader(title: 'الوصف'),
                      const SizedBox(height: 8),
                      Text(
                        _auction.car.description.isNotEmpty
                            ? _auction.car.description
                            : 'سيارة بحالة ممتازة، محرك قوي واقتصادي، جميع الصيانات في المركز المعتمد، لا تحتاج لأي مصاريف إضافية.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // قسم تاريخ المزايدات المحسن مع عرض الكل التفاعلي
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SectionHeader(title: 'تاريخ المزايدات'),
                          TextButton(
                            onPressed: () {
                              AppSnackbar.showInfo(
                                context,
                                title: 'سجل المزايدات سيظهر هنا قريباً',
                              );
                            },
                            child: Text(
                              'عرض الكل',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildBidsList(),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // منطقة الإجراءات السفلية: بار المزايدة أثناء النشاط، أو أزرار
          // قبول/رفض/تأكيد/تراجع بعد الإغلاق حسب دور المستخدم ومرحلة المزاد
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionArea(minBid),
          ),
        ],
      ),
    );
  }

  Widget _bottomSheetContainer({required Widget child}) =>
      BottomSheetContainer(child: child);

  Widget _buildBidBar(double minBid) => BidBar(
    minBid: minBid,
    controller: _bidController,
    isSubmitting: _isSubmittingBid,
    onSubmit: _submitBid,
    formatPrice: _formatPrice,
  );

  // زر إجراء رئيسي واحد (تأكيد إتمام البيع) أو زوج أزرار (قبول/رفض)
  Widget _buildActionButtonsBar({required List<ActionButtonSpec> buttons}) =>
      ActionButtonsBar(buttons: buttons, isProcessing: _isProcessingAction);

  // شريط معلوماتي بلا إجراء (لغير البائع/الفائز، أو للفائز أثناء انتظار
  // قرار البائع، أو بعد اكتمال/رفض/إلغاء الصفقة)
  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) => InfoBanner(icon: icon, color: color, text: text);

  // نفس شريط المعلومات، مع زر "تحديث" لإعادة جلب حالة المزاد من السيرفر
  // يدوياً؛ يُستخدم في حالة انتهاء العدّاد محلياً بانتظار إغلاق حقيقي
  Widget _buildInfoBannerWithRefresh({
    required IconData icon,
    required Color color,
    required String text,
  }) => InfoBannerWithRefresh(
    icon: icon,
    color: color,
    text: text,
    isRefreshing: _isRefreshingStatus,
    onRefresh: _refreshAuctionStatus,
  );

  // شارة "مزاد مباشر" كانت ثابتة دائماً بغض النظر عن حالة المزاد الفعلية،
  // فتبقى معروضة حتى بعد الانتهاء وتوحي للمستخدم بأن المزاد ما زال قائماً.
  // الآن تعكس المرحلة الحقيقية المشتقة من status/final_price_status.
  Widget _buildLiveBadge() {
    late final Color color;
    late final String label;
    late final bool pulsing;

    switch (_phase) {
      case _AuctionPhase.bidding:
        color = AppColors.primary;
        label = 'مزاد مباشر';
        pulsing = true;
        break;
      case _AuctionPhase.pendingApproval:
        color = Colors.orange;
        label = 'قيد المراجعة';
        pulsing = false;
        break;
      case _AuctionPhase.completed:
        color = Colors.green;
        label = 'مكتمل';
        pulsing = false;
        break;
      case _AuctionPhase.rejected:
        color = Colors.red;
        label = 'مرفوض';
        pulsing = false;
        break;
      case _AuctionPhase.withdrawn:
        color = Colors.red;
        label = 'تراجع الفائز';
        pulsing = false;
        break;
      case _AuctionPhase.cancelled:
        color = Colors.grey;
        label = 'ملغى';
        pulsing = false;
        break;
      case _AuctionPhase.timeUpAwaitingClose:
      case _AuctionPhase.closedNoWinner:
      case _AuctionPhase.awaitingSellerDecision:
      case _AuctionPhase.awaitingSaleCompletion:
        color = Colors.black87;
        label = 'انتهى';
        pulsing = false;
        break;
      case _AuctionPhase.unknown:
        return const SizedBox.shrink();
    }

    return LiveBadge(color: color, label: label, pulsing: pulsing);
  }

  Widget _buildBottomActionArea(double minBid) {
    switch (_phase) {
      case _AuctionPhase.bidding:
        if (_isOwner) {
          return _buildInfoBanner(
            icon: Icons.info_outline,
            color: Colors.blueGrey,
            text: 'المزاد نشط الآن، لا يمكنك المزايدة على سيارتك الخاصة.',
          );
        }
        return _buildBidBar(minBid);

      case _AuctionPhase.pendingApproval:
        return _buildInfoBanner(
          icon: Icons.hourglass_top,
          color: Colors.orange,
          text: 'المزاد قيد المراجعة الإدارية، سيصبح نشطاً بعد الاعتماد.',
        );

      case _AuctionPhase.timeUpAwaitingClose:
        // انتهى العدّاد عندنا لكن حالة المزاد بالسيرفر ما زالت "نشط"، لذلك
        // لا نعرض أزرار القبول/الرفض حتى يصل تأكيد إغلاق فعلي من الخادم
        // تفادياً لتكرار خطأ "لا يمكن قبول السعر قبل إغلاق المزاد".
        return _buildInfoBannerWithRefresh(
          icon: Icons.hourglass_bottom,
          color: Colors.orange,
          text:
              'انتهى وقت المزاد، بانتظار إغلاقه تلقائياً من النظام لتحديد الفائز.',
        );

      case _AuctionPhase.closedNoWinner:
        // السيرفر يرفض أي قبول/رفض إن لم يوجد winner_id (بالضبط رسالة
        // "لا يمكن قبول السعر قبل إغلاق المزاد وتحديد الفائز")، لذلك لا
        // نعرض هذين الزرين هنا مطلقاً تفادياً لضغطة فاشلة أكيدة.
        return _buildInfoBannerWithRefresh(
          icon: Icons.info_outline,
          color: Colors.blueGrey,
          text:
              'أُغلق المزاد لكن لم يُحدَّد فائز له بعد من النظام '
              '(غالباً لعدم وجود مزايدات كافية، أو بانتظار خدمة إغلاق '
              'المزادات). لا يمكن اتخاذ قرار قبل تحديد الفائز.',
        );

      case _AuctionPhase.awaitingSellerDecision:
        if (_isOwner) {
          return _buildActionButtonsBar(
            buttons: [
              ActionButtonSpec(
                label: 'رفض السعر',
                icon: Icons.close_rounded,
                color: Colors.red,
                filled: false,
                onTap: _rejectFinalPrice,
              ),
              ActionButtonSpec(
                label: 'قبول السعر النهائي',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                filled: true,
                onTap: _acceptFinalPrice,
              ),
            ],
          );
        }
        if (_isWinner) {
          return _buildInfoBannerWithRefresh(
            icon: Icons.hourglass_bottom,
            color: AppColors.primary,
            text:
                'أنت الفائز بهذا المزاد، بانتظار قرار البائع بشأن السعر النهائي.',
          );
        }
        return _buildInfoBannerWithRefresh(
          icon: Icons.gavel,
          color: Colors.blueGrey,
          text: 'انتهى المزاد، بانتظار قرار البائع النهائي.',
        );

      case _AuctionPhase.awaitingSaleCompletion:
        if (_isOwner) {
          return _buildActionButtonsBar(
            buttons: [
              ActionButtonSpec(
                label: 'تأكيد إتمام البيع',
                icon: Icons.task_alt,
                color: AppColors.primary,
                filled: true,
                onTap: _completeSale,
              ),
            ],
          );
        }
        if (_isWinner) {
          return _buildActionButtonsBar(
            buttons: [
              ActionButtonSpec(
                label: 'التراجع عن الصفقة',
                icon: Icons.undo_rounded,
                color: Colors.red,
                filled: false,
                onTap: _winnerWithdraw,
              ),
            ],
          );
        }
        return _buildInfoBanner(
          icon: Icons.handshake_outlined,
          color: Colors.green,
          text:
              'تم قبول السعر النهائي، بانتظار إتمام البيع بين البائع والفائز.',
        );

      case _AuctionPhase.completed:
        return _buildInfoBanner(
          icon: Icons.check_circle,
          color: Colors.green,
          text: 'تم إتمام عملية البيع بنجاح.',
        );

      case _AuctionPhase.rejected:
        return _buildInfoBanner(
          icon: Icons.cancel_outlined,
          color: Colors.red,
          text: 'تم رفض السعر النهائي من قبل البائع، وأُعيد العربون للفائز.',
        );

      case _AuctionPhase.withdrawn:
        return _buildInfoBanner(
          icon: Icons.cancel_outlined,
          color: Colors.red,
          text: 'تراجع الفائز عن الصفقة، وصودر عربونه لصالح البائع.',
        );

      case _AuctionPhase.cancelled:
        return _buildInfoBanner(
          icon: Icons.block,
          color: Colors.grey,
          text: 'تم إلغاء هذا المزاد.',
        );

      case _AuctionPhase.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeCircularUnit(String value, String label) =>
      TimeCircularUnit(value: value, label: label);

  Widget _buildAuctionGridSpecs() => AuctionGridSpecs(auction: _auction);

  // قائمة المزايدات الحقيقية القادمة من الـ API (الأحدث أولاً)
  Widget _buildBidsList() => BidsList(
    bids: _auction.bids,
    formatPrice: _formatPrice,
    parsePrice: _parsePrice,
    formatDateTime: _formatDateTime,
  );

  String _formatRemaining(Duration remaining) {
    if (remaining.isNegative) return 'انتهى المزاد';
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    if (days > 0) return '$days يوم و $hours ساعة';
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) return '$hours ساعة و $minutes دقيقة';
    return '$minutes دقيقة';
  }

  String _formatDateTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
    return 'قبل ${diff.inDays} يوم';
  }

  // إرسال المزايدة فعلياً عبر AuctionService، ثم تحديث بيانات المزاد من السيرفر
  Future<void> _submitBid() async {
    final amount = double.tryParse(_bidController.text.trim());
    if (amount == null || amount <= 0) {
      AppSnackbar.showWarning(context, title: 'أدخل مبلغ مزايدة صحيح');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmittingBid = true);

    try {
      await _auctionService.placeBid(auctionId: _auction.id, amount: amount);
      final refreshed = await _auctionService.getAuctionDetails(_auction.id);

      if (!mounted) return;
      setState(() {
        _auction = Auction.fromJson(refreshed);
        _isSubmittingBid = false;
      });
      _bidController.clear();
      AppSnackbar.showSuccess(context, title: 'تم تسجيل عرض المزايدة بنجاح');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingBid = false);

      if (e is ApiException && e.isInsufficientBalance) {
        AppSnackbar.showError(
          context,
          title: 'رصيدك غير كافٍ',
          subtitle: 'رصيد محفظتك غير كافٍ لتقديم هذه المزايدة',
          actionLabel: 'شحن المحفظة',
          onAction: _goToWallet,
        );
        return;
      }

      AppSnackbar.showError(
        context,
        title: 'تعذّر تقديم المزايدة',
        debugMessage: e,
      );
    }
  }

  // مربع تأكيد عام لإجراءات المزاد النهائية (لا يمكن التراجع عنها)
  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  confirmLabel,
                  style: TextStyle(
                    color: confirmColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  Future<void> _refreshAuction() async {
    try {
      // نفس الحل المطبّق بشاشة القائمة: لا يوجد مجدول سيرفر يغلق المزادات
      // المنتهية تلقائياً، فنحاول إغلاقها هنا في كل تحديث (تلقائي أو يدوي)
      // قبل جلب أحدث نسخة — بأمان، لا تفعل شيئاً لو لم ينتهِ وقت المزاد بعد.
      await _auctionService.closeExpiredAuctions();
    } catch (_) {
      // تجاهل فشل الإغلاق التلقائي؛ لا يجب أن يمنع عرض بيانات المزاد الحالية
    }
    try {
      final refreshed = await _auctionService.getAuctionDetails(_auction.id);
      if (!mounted) return;
      setState(() => _auction = Auction.fromJson(refreshed));
    } catch (_) {
      // نتجاهل فشل التحديث الصامت؛ القرار المحلي كافٍ لعرض المرحلة الصحيحة
    }
  }

  // نفس التحديث لكن مع مؤشر تحميل ورسالة نتيجة، يُستخدم عند ضغط المستخدم
  // على زر "تحديث" يدوياً بانتظار إغلاق المزاد فعلياً من السيرفر
  Future<void> _refreshAuctionStatus() async {
    setState(() => _isRefreshingStatus = true);
    final previousStatus = _auction.status;
    await _refreshAuction();
    if (!mounted) return;
    setState(() => _isRefreshingStatus = false);
    if (_auction.status == previousStatus) {
      AppSnackbar.showInfo(
        context,
        title: 'لم تتغير حالة المزاد بعد',
        subtitle: 'حاول التحديث مرة أخرى لاحقاً',
      );
    }
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required _AuctionPhase nextPhase,
    required String successMessage,
  }) async {
    setState(() => _isProcessingAction = true);
    try {
      await action();
      await _refreshAuction();
      if (!mounted) return;
      setState(() {
        _localPhaseOverride = nextPhase;
        _isProcessingAction = false;
      });
      AppSnackbar.showSuccess(context, title: successMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAction = false);
      AppSnackbar.showError(
        context,
        title: 'تعذّر إتمام الإجراء',
        subtitle: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAction = false);
      AppSnackbar.showError(context, title: 'فشلت العملية', debugMessage: e);
    }
  }

  // البائع يقبل السعر النهائي بعد انتهاء المزاد: يبقي عربون الفائز محجوزاً
  // تمهيداً للقاء خارج التطبيق وتأكيد إتمام البيع لاحقاً
  Future<void> _acceptFinalPrice() async {
    final confirmed = await _confirmAction(
      title: 'قبول السعر النهائي',
      message:
          'بقبولك السعر النهائي (${_formatPrice(_parsePrice(_auction.currentPrice))}) '
          'يبقى عربون الفائز محجوزاً، وعليك التنسيق معه لإتمام البيع خارج '
          'التطبيق ثم تأكيد إتمام البيع من هنا.',
      confirmLabel: 'قبول',
      confirmColor: Colors.green,
    );
    if (!confirmed) return;
    await _runAction(
      action: () => _auctionService.acceptFinalPrice(_auction.id),
      nextPhase: _AuctionPhase.awaitingSaleCompletion,
      successMessage: 'تم قبول السعر النهائي بنجاح',
    );
  }

  // البائع يرفض السعر النهائي: يُعاد عربون الفائز إلى محفظته
  Future<void> _rejectFinalPrice() async {
    final confirmed = await _confirmAction(
      title: 'رفض السعر النهائي',
      message:
          'برفضك السعر النهائي يُعاد عربون الفائز إلى محفظته، وتُغلق '
          'صفقة هذا المزاد نهائياً. هل أنت متأكد؟',
      confirmLabel: 'رفض',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;
    await _runAction(
      action: () => _auctionService.rejectFinalPrice(_auction.id),
      nextPhase: _AuctionPhase.rejected,
      successMessage: 'تم رفض السعر النهائي',
    );
  }

  // البائع يؤكد إتمام البيع فعلياً بعد اللقاء مع الفائز خارج التطبيق،
  // ما يحرر عربون الفائز نهائياً
  Future<void> _completeSale() async {
    final confirmed = await _confirmAction(
      title: 'تأكيد إتمام البيع',
      message:
          'اضغط تأكيد فقط بعد إتمام تسليم السيارة واستلام كامل المبلغ من '
          'الفائز خارج التطبيق. سيتم عندها تحرير عربونه المحجوز.',
      confirmLabel: 'تأكيد الإتمام',
      confirmColor: AppColors.primary,
    );
    if (!confirmed) return;
    await _runAction(
      action: () => _auctionService.completeSale(_auction.id),
      nextPhase: _AuctionPhase.completed,
      successMessage: 'تم تأكيد إتمام البيع بنجاح',
    );
  }

  // الفائز يتراجع عن الصفقة بعد قبول البائع للسعر: يُصادَر عربونه لصالح البائع
  Future<void> _winnerWithdraw() async {
    final confirmed = await _confirmAction(
      title: 'التراجع عن الصفقة',
      message:
          'تراجعك عن هذه الصفقة سيؤدي لمصادرة العربون الذي حجزته لصالح '
          'البائع، ولا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟',
      confirmLabel: 'تراجع نهائياً',
      confirmColor: Colors.red,
    );
    if (!confirmed) return;
    await _runAction(
      action: () => _auctionService.winnerWithdraw(_auction.id),
      nextPhase: _AuctionPhase.withdrawn,
      successMessage: 'تم تسجيل تراجعك عن الصفقة',
    );
  }

  // يفتح شاشة المحفظة المناسبة (شركة/فرد) حسب نوع الحساب المخزّن محلياً
  Future<void> _goToWallet() async {
    final user = await AuthStorage.getUser();
    final accountType = user?['account_type']?.toString();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                accountType == 'company'
                    ? const CompanyWalletScreen()
                    : const IndividualWalletScreen(),
      ),
    );
  }
}
