import 'package:flutter/material.dart';
import 'package:mators_car/data/models/promotion_model.dart';
import 'package:mators_car/services/controllers/promotion_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

class PromotionDetailScreen extends StatefulWidget {
  final Promotion promotion;

  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  final PromotionService _promotionService = PromotionService();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _valueController;
  late final TextEditingController _quantityController;
  late String _type;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _titleController = TextEditingController(text: p.title);
    _descriptionController = TextEditingController(text: p.description);
    _valueController = TextEditingController(text: p.value.toStringAsFixed(0));
    _quantityController = TextEditingController(text: p.quantity.toString());
    _type = p.type;
    _startDate = p.startDate;
    _endDate = p.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'اختر التاريخ';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: isStart ? now.subtract(const Duration(days: 365)) : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _promotionService.updatePromotion(
        promotionId: widget.promotion.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        value: double.tryParse(_valueController.text.trim()) ?? 0,
        startDate: _startDate ?? DateTime.now(),
        endDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'فشل حفظ التعديلات: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف العرض'),
            content: const Text('هل أنت متأكد من حذف هذا العرض الترويجي؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _promotionService.deletePromotion(widget.promotion.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppSnackbar.showError(context, title: 'تعذّر حذف العرض', debugMessage: e);
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
          'تعديل العرض',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon:
                _isDeleting
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isDeleting ? null : _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
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
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _type == 'discount'
                        ? 'خصم ${_valueController.text.trim()}%'
                        : _valueController.text.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.promotion.status == 'rejected' &&
                widget.promotion.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'سبب الرفض: ${widget.promotion.rejectionReason}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _label('عنوان العرض'),
            _textField(_titleController),
            const SizedBox(height: 14),
            _label('وصف العرض'),
            _textField(_descriptionController, maxLines: 3),
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
                      _label('الكمية المتاحة'),
                      _textField(
                        _quantityController,
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
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'حفظ التعديلات',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
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
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
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
            Text(_formatDate(date), style: const TextStyle(fontSize: 13)),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
