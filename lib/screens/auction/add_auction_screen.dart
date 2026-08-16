import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/models/auction_model.dart';
import 'package:mators_car/services/auction_service.dart';
import 'package:mators_car/services/company_service.dart';
import 'package:mators_car/services/subscription_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constans.dart';
import 'package:mators_car/screens/promotions/subscription_screen.dart';

// شاشة إنشاء مزاد جديد، أو تعديل مزاد قائم إذا مُرِّر [existingAuction].
// إنشاء المزاد -حسب توثيق الـ API- يتطلب اشتراكاً نشطاً وسيارة معتمدة
// يملكها المستخدم (بنفس شرط العروض الترويجية تماماً).
class AddAuctionScreen extends StatefulWidget {
  final Auction? existingAuction;

  const AddAuctionScreen({super.key, this.existingAuction});

  bool get isEditing => existingAuction != null;

  @override
  State<AddAuctionScreen> createState() => _AddAuctionScreenState();
}

class _AddAuctionScreenState extends State<AddAuctionScreen> {
  final AuctionService _auctionService = AuctionService();
  final CompanyService _carService = CompanyService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  int _step = 0; // 0: السيارة، 1: التفاصيل، 2: المراجعة

  final _startingPriceController = TextEditingController();
  final _durationController = TextEditingController(text: '24');

  Map<String, dynamic>? _selectedCar;
  late Future<List<Map<String, dynamic>>> _myApprovedCarsFuture;

  bool _isSubmitting = false;
  String? _errorMessage;
  bool? _isSubscribed;

  @override
  void initState() {
    super.initState();
    _myApprovedCarsFuture = _loadApprovedCars();
    _checkSubscription();

    if (widget.isEditing) {
      final auction = widget.existingAuction!;
      // بالتعديل السيارة مثبّتة مسبقاً (لا يمكن تغيير سيارة مزاد قائم)
      _selectedCar = {
        'id': auction.carId,
        'make': auction.car.make,
        'model': auction.car.model,
        'year': auction.car.year,
        'images': auction.car.images,
      };
      _startingPriceController.text = auction.startingPrice;
      final hours = auction.endTime.difference(auction.startTime).inHours;
      _durationController.text = (hours > 0 ? hours : 24).toString();
      _step = 1; // نبدأ مباشرة من خطوة التفاصيل بوضع التعديل
    }
  }

  Future<List<Map<String, dynamic>>> _loadApprovedCars() async {
    final cars = await _carService.getMyCars();
    return cars.where((car) {
      final status = (car['approval_status'] ?? car['status'] ?? '').toString();
      return status == 'approved';
    }).toList();
  }

  Future<void> _checkSubscription() async {
    try {
      final status = await _subscriptionService.getSubscriptionStatus();
      final isActive = SubscriptionService.isActive(status);
      if (!mounted) return;
      setState(() => _isSubscribed = isActive);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubscribed = null);
    }
  }

  Future<void> _showSubscriptionRequiredSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => _AuctionSubscriptionRequiredSheet(
            onSubscribeTap: () async {
              Navigator.pop(sheetContext);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
              await _checkSubscription();
            },
          ),
    );
  }

  @override
  void dispose() {
    _startingPriceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (_selectedCar == null) {
        setState(() => _errorMessage = 'اختر سيارة أولاً للمتابعة');
        return;
      }
    }
    if (_step == 1) {
      final price = double.tryParse(_startingPriceController.text.trim());
      final duration = int.tryParse(_durationController.text.trim());
      if (price == null || price <= 0) {
        setState(() => _errorMessage = 'أدخل سعراً ابتدائياً صحيحاً');
        return;
      }
      if (duration == null || duration <= 0) {
        setState(() => _errorMessage = 'أدخل مدة مزاد صحيحة بالساعات');
        return;
      }
    }
    setState(() {
      _errorMessage = null;
      _step += 1;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _errorMessage = null;
      _step -= 1;
    });
  }

  Future<void> _submit() async {
    if (!widget.isEditing && _isSubscribed == false) {
      await _showSubscriptionRequiredSheet();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final price = double.tryParse(_startingPriceController.text.trim()) ?? 0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 24;

    try {
      if (widget.isEditing) {
        await _auctionService.updateAuction(
          auctionId: widget.existingAuction!.id,
          startingPrice: price,
          durationHours: duration,
        );
      } else {
        await _auctionService.createAuction(
          carId: int.tryParse('${_selectedCar!['id']}') ?? 0,
          startingPrice: price,
          durationHours: duration,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSubscribed = e.isSubscriptionRequired ? false : _isSubscribed;
      });
      if (e.isSubscriptionRequired) {
        await _showSubscriptionRequiredSheet();
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'فشلت العملية: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['السيارة', 'التفاصيل', 'المراجعة'];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.isEditing ? 'تعديل المزاد' : 'إنشاء مزاد',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          _buildStepper(steps),
          if (!widget.isEditing && _isSubscribed == false)
            _buildSubscriptionBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child:
                  widget.isEditing
                      ? (_step == 1 ? _buildDetailsStep() : _buildReviewStep())
                      : [
                        _buildCarStep(),
                        _buildDetailsStep(),
                        _buildReviewStep(),
                      ][_step],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'يتطلب إنشاء مزاد اشتراكاً نشطاً',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: _showSubscriptionRequiredSheet,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'اشترك الآن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(List<String> steps) {
    // بوضع التعديل نعرض فقط خطوتي التفاصيل والمراجعة (السيارة مثبّتة)
    final visibleSteps =
        widget.isEditing ? steps.sublist(1) : steps;
    final activeIndex = widget.isEditing ? _step - 1 : _step;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(visibleSteps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < activeIndex;
            return Container(
              width: 40,
              height: 2,
              color: leftDone ? AppColors.primary : Colors.grey.shade300,
            );
          }
          final index = i ~/ 2;
          final isDone = index < activeIndex;
          final isCurrent = index == activeIndex;
          return CircleAvatar(
            radius: 14,
            backgroundColor:
                isDone || isCurrent
                    ? AppColors.primary
                    : Colors.grey.shade300,
            child:
                isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          );
        }),
      ),
    );
  }

  Widget _buildCarStep() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _myApprovedCarsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              'تعذر جلب سياراتك\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final cars = snapshot.data ?? [];
        if (cars.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              'لا توجد لديك سيارات معتمدة بعد. أضف سيارة وانتظر اعتمادها '
              'من الإدارة قبل إنشاء مزاد عليها.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر السيارة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...cars.map((car) {
              final selected = _selectedCar != null && _selectedCar!['id'] == car['id'];
              final imageUrl = AppConstants.resolveImageUrl(
                car['images'] is List && (car['images'] as List).isNotEmpty
                    ? (car['images'] as List).first.toString()
                    : null,
              );
              return GestureDetector(
                onTap: () => setState(() => _selectedCar = car),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.black12,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            imageUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 112,
                                  placeholder:
                                      (_, __) => Container(
                                        width: 56,
                                        height: 56,
                                        color: const Color(0xFFF0F0F0),
                                      ),
                                  errorWidget:
                                      (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: const Color(0xFFF0F0F0),
                                      ),
                                )
                                : Container(
                                  width: 56,
                                  height: 56,
                                  color: const Color(0xFFF0F0F0),
                                  child: const Icon(Icons.directions_car),
                                ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${car['make'] ?? ''} ${car['model'] ?? ''} ${car['year'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected ? AppColors.primary : Colors.black26,
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_errorMessage != null) _buildErrorText(),
          ],
        );
      },
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل المزاد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        const Text('السعر الابتدائي (ل.س)'),
        const SizedBox(height: 6),
        TextField(
          controller: _startingPriceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'مثال: 20000000',
          ),
        ),
        const SizedBox(height: 16),
        const Text('مدة المزاد (بالساعات)'),
        const SizedBox(height: 6),
        TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: 'مثال: 24',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'على المزايدين حجز عربون من محفظتهم عند المزايدة، بنسبة '
                  'تحددها إعدادات المنصة.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) _buildErrorText(),
      ],
    );
  }

  Widget _buildReviewStep() {
    final car = _selectedCar ?? {};
    final imageUrl = AppConstants.resolveImageUrl(
      car['images'] is List && (car['images'] as List).isNotEmpty
          ? (car['images'] as List).first.toString()
          : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مراجعة المزاد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder:
                  (_, __) => Container(height: 170, color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '${car['make'] ?? ''} ${car['model'] ?? ''} ${car['year'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _reviewRow('السعر الابتدائي', '${_startingPriceController.text} ل.س'),
        _reviewRow('مدة المزاد', '${_durationController.text} ساعة'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'بإنشاء هذا المزاد، أنت توافق على شروط وأحكام المزادات.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        if (_errorMessage != null) _buildErrorText(),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }

  bool get _isLastStep => widget.isEditing ? _step == 2 : _step == 2;

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _back,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                      : (_isLastStep ? _submit : _next),
              style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        _isLastStep
                            ? (widget.isEditing ? 'حفظ التعديلات' : 'إنشاء المزاد')
                            : 'متابعة',
                        style: const TextStyle(color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// بطاقة سفلية (bottom sheet) تُعرض عند محاولة إنشاء مزاد دون اشتراك نشط.
class _AuctionSubscriptionRequiredSheet extends StatelessWidget {
  final VoidCallback onSubscribeTap;

  const _AuctionSubscriptionRequiredSheet({required this.onSubscribeTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.gavel, color: Colors.white, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'يتطلب إنشاء مزاد اشتراكاً نشطاً',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'اشترك الآن حتى تتمكن من طرح سياراتك للمزايدة.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onSubscribeTap,
              style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'اشترك الآن',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً'),
            ),
          ],
        ),
      ),
    );
  }
}
