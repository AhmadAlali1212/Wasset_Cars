import 'package:flutter/material.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/services/controllers/auction_service.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/services/controllers/subscription_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/screens/promotions/subscription_screen.dart';
import 'package:mators_car/widgets/autction/add_auction_widgets.dart';

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
          (sheetContext) => AuctionSubscriptionRequiredSheet(
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
        _errorMessage = 'فشلت العملية: ${ApiException.userMessage(e)}';
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
          AuctionStepper(
            steps: steps,
            step: _step,
            isEditing: widget.isEditing,
          ),
          if (!widget.isEditing && _isSubscribed == false)
            AuctionSubscriptionBanner(
              onSubscribeTap: _showSubscriptionRequiredSheet,
            ),
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
          AuctionBottomBar(
            isSubmitting: _isSubmitting,
            isLastStep: _isLastStep,
            isEditing: widget.isEditing,
            onBack: _back,
            onNext: _next,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildCarStep() => AuctionCarStep(
    carsFuture: _myApprovedCarsFuture,
    selectedCar: _selectedCar,
    onSelectCar: (car) => setState(() => _selectedCar = car),
    errorMessage: _errorMessage,
  );

  Widget _buildDetailsStep() => AuctionDetailsStep(
    startingPriceController: _startingPriceController,
    durationController: _durationController,
    errorMessage: _errorMessage,
  );

  Widget _buildReviewStep() => AuctionReviewStep(
    selectedCar: _selectedCar,
    startingPriceText: _startingPriceController.text,
    durationText: _durationController.text,
    errorMessage: _errorMessage,
  );

  bool get _isLastStep => widget.isEditing ? _step == 2 : _step == 2;
}
