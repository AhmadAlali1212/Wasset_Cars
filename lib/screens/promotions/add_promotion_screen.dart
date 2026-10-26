import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/promotion_service.dart';
import 'package:mators_car/services/controllers/subscription_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/services/local_promotions_cache.dart';
import 'subscription_screen.dart';
import 'package:mators_car/widgets/promotions/add_promotion_widgets.dart';

class AddPromotionScreen extends StatefulWidget {
  const AddPromotionScreen({super.key});

  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  final PromotionService _promotionService = PromotionService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  int _step = 0; // 0: معلومات أساسية، 1: مراجعة ونشر

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  String _type = 'discount';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  // حالة الاشتراك: null = لم يتم التحقق بعد
  bool? _isSubscribed;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // تحقق مبكر من حالة الاشتراك عند فتح الشاشة، لعرض تنبيه للمستخدم
  // قبل أن يعبّئ النموذج ثم يفاجَأ برفض النشر لاحقاً.
  Future<void> _checkSubscription() async {
    try {
      final status = await _subscriptionService.getSubscriptionStatus();
      final isActive = SubscriptionService.isActive(status);
      if (!mounted) return;
      setState(() => _isSubscribed = isActive);
    } catch (_) {
      // تعذّر التحقق (مشكلة شبكة مثلاً)؛ نترك الأمر ونعتمد على تحقق
      // السيرفر نفسه عند محاولة النشر.
      if (!mounted) return;
      setState(() => _isSubscribed = null);
    }
  }

  // يعرض بطاقة "الاشتراك مطلوب" ويقود المستخدم لشاشة الاشتراك الفعلية،
  // ثم يعيد التحقق من الحالة عند العودة.
  Future<void> _showSubscriptionRequiredSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SubscriptionRequiredSheet(
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

  bool get _basicInfoValid =>
      _titleController.text.trim().isNotEmpty &&
      _valueController.text.trim().isNotEmpty &&
      _startDate != null &&
      _endDate != null &&
      _quantityController.text.trim().isNotEmpty;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_startDate ?? now).add(const Duration(days: 7)),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
      helpText: isStart ? 'تاريخ بداية العرض' : 'تاريخ نهاية العرض',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'اختر التاريخ';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    // إن كنّا نعلم مسبقاً أن الاشتراك غير مفعّل، لا داعي لإرسال الطلب أصلاً؛
    // نعرض بطاقة الاشتراك مباشرة.
    if (_isSubscribed == false) {
      await _showSubscriptionRequiredSheet();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final created = await _promotionService.createPromotion(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        value: double.tryParse(_valueController.text.trim()) ?? 0,
        startDate: _startDate!,
        endDate: _endDate!,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      );
      if (created['id'] != null) {
        await LocalPromotionsCache.add(created);
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
        _errorMessage = 'فشل إنشاء العرض: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إضافة عرض جديد',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          PromotionStepper(step: _step),
          if (_isSubscribed == false)
            PromotionSubscriptionBanner(onSubscribeTap: _showSubscriptionRequiredSheet),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child:
                  _step == 0
                      ? PromotionBasicInfoStep(
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        type: _type,
                        onTypeChanged: (v) => setState(() => _type = v ?? 'discount'),
                        valueController: _valueController,
                        quantityController: _quantityController,
                        startDate: _startDate,
                        endDate: _endDate,
                        onPickStartDate: () => _pickDate(isStart: true),
                        onPickEndDate: () => _pickDate(isStart: false),
                        formatDate: _formatDate,
                        onFieldChanged: () => setState(() {}),
                      )
                      : PromotionReviewStep(
                        title: _titleController.text.trim(),
                        type: _type,
                        value: _valueController.text.trim(),
                        startDate: _startDate,
                        endDate: _endDate,
                        formatDate: _formatDate,
                        quantity: _quantityController.text.trim(),
                        description: _descriptionController.text.trim(),
                        errorMessage: _errorMessage,
                      ),
            ),
          ),
          PromotionBottomBar(
            step: _step,
            isSubmitting: _isSubmitting,
            basicInfoValid: _basicInfoValid,
            onBack: () => setState(() => _step -= 1),
            onContinue: () => setState(() => _step = 1),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}
