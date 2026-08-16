import 'package:flutter/material.dart';
import 'package:mators_car/services/promotion_service.dart';
import 'package:mators_car/services/subscription_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/services/local_promotions_cache.dart';
import 'package:mators_car/ulits/colors.dart';
import 'subscription_screen.dart';

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
      builder: (sheetContext) => _SubscriptionRequiredSheet(
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
          _buildStepper(),
          if (_isSubscribed == false) _buildSubscriptionBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _step == 0 ? _buildBasicInfoStep() : _buildReviewStep(),
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
              'يتطلب نشر عرض ترويجي اشتراكاً نشطاً',
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

  Widget _buildStepper() {
    final titles = ['معلومات أساسية', 'مراجعة ونشر'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(titles.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < _step;
            return Container(
              width: 40,
              height: 2,
              color: leftDone ? AppColors.primary : Colors.grey.shade300,
            );
          }
          final index = i ~/ 2;
          final isDone = index < _step;
          final isCurrent = index == _step;
          return Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    isDone || isCurrent
                        ? AppColors.primary
                        : Colors.grey.shade300,
                child:
                    isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المعلومات الأساسية',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _label('عنوان العرض'),
        _textField(_titleController, hint: 'مثال: خصم الصيف'),
        const SizedBox(height: 14),
        _label('وصف العرض'),
        _textField(
          _descriptionController,
          hint: 'وصف مختصر عن العرض',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        _label('نوع العرض'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _type,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              items: const [
                DropdownMenuItem(value: 'discount', child: Text('خصم (%)')),
                DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'discount'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(_type == 'discount' ? 'قيمة الخصم (%)' : 'القيمة'),
                  _textField(
                    _valueController,
                    hint: _type == 'discount' ? '20' : '100000',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('الكمية'),
                  _textField(
                    _quantityController,
                    hint: '100',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('تاريخ البداية'),
                  _dateBox(_startDate, () => _pickDate(isStart: true)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('تاريخ النهاية'),
                  _dateBox(_endDate, () => _pickDate(isStart: false)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
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
            children: [
              Text(
                _titleController.text.trim().isEmpty
                    ? 'عنوان العرض'
                    : _titleController.text.trim(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _type == 'discount'
                    ? 'خصم ${_valueController.text.trim()}%'
                    : _valueController.text.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_formatDate(_startDate)}  →  ${_formatDate(_endDate)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _reviewRow('الكمية', _quantityController.text.trim()),
        _reviewRow(
          'الوصف',
          _descriptionController.text.trim().isEmpty
              ? '—'
              : _descriptionController.text.trim(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.directions_car_filled,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'سيشمل هذا العرض تلقائياً جميع سياراتك المعروضة للبيع، '
                  'وستظهر كلها في قسم "العروض الترويجية" بمجرد اعتماد العرض.',
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        const Text(
          'سيخضع العرض لمراجعة الإدارة قبل نشره للعموم.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );

  Widget _textField(
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _dateBox(DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 13,
                color: date == null ? Colors.grey.shade400 : Colors.black,
              ),
            ),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step -= 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('رجوع'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isSubmitting
                      ? null
                      : _step == 0
                      ? (_basicInfoValid ? () => setState(() => _step = 1) : null)
                      : _submit,
              style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                        _step == 0 ? 'متابعة' : 'نشر العرض',
                        style: const TextStyle(color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// بطاقة سفلية (bottom sheet) تظهر عندما يحاول المستخدم نشر عرض ترويجي
// دون اشتراك نشط، وتقوده مباشرة لشاشة الاشتراك الحقيقية.
class _SubscriptionRequiredSheet extends StatelessWidget {
  final VoidCallback onSubscribeTap;

  const _SubscriptionRequiredSheet({required this.onSubscribeTap});

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
                  Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                  SizedBox(height: 10),
                  Text(
                    'يتطلب نشر العروض الترويجية اشتراكاً نشطاً',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'اشترك الآن للاستفادة من نشر عروضك الترويجية وإدارتها.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SheetFeatureRow(text: 'نشر عروض ترويجية غير محدودة'),
            const _SheetFeatureRow(text: 'ظهور العروض للمستخدمين مباشرة'),
            const _SheetFeatureRow(text: 'متابعة إحصائيات كل عرض'),
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

class _SheetFeatureRow extends StatelessWidget {
  final String text;
  const _SheetFeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
