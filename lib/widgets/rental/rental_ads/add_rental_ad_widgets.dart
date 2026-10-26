import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/ulits/colors.dart';

/// ودجات نموذج إضافة إعلان تأجير — استُخرجت من دوال _build... الخاصة
/// بشاشة add_rental_Ad_screen.dart دون أي تغيير بالتصميم أو المنطق.

/// عنوان القسم الفرعي الموحّد أعلى كل بطاقة بالنموذج (نمط بخط رمادي غامق).
class RentalFormSectionLabel extends StatelessWidget {
  final String text;
  const RentalFormSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
        fontSize: 16,
      ),
    );
  }
}

/// الحاوية البيضاء الموحّدة (ظل خفيف، حواف دائرية) التي تحيط بكل قسم
/// بالنموذج.
class RentalFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const RentalFormCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// رأس شاشة إضافة الإعلان (عنوان + وصف تعريفي قصير).
class RentalAdHeaderSection extends StatelessWidget {
  const RentalAdHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إضافة إعلان تأجير جديد',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'املأ النموذج التالي لإضافة إعلان تأجير سيارتك',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// قسم رفع صور السيارة (حتى 5 صور) — يعرض مربّع إضافة فارغ أو صف أفقي
/// من الصور المختارة مع زر حذف لكل صورة وزر "إضافة المزيد".
class RentalAdImageUploadSection extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onPickImages;
  final void Function(int index) onRemoveImage;

  const RentalAdImageUploadSection({
    super.key,
    required this.images,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RentalFormSectionLabel('صور السيارة'),
        const SizedBox(height: 8),
        RentalFormCard(
          child: SizedBox(
            height: 150,
            child:
                images.isEmpty
                    ? InkWell(
                      onTap: onPickImages,
                      borderRadius: BorderRadius.circular(15),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'إضافة صور السيارة',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(يمكن إضافة حتى 5 صور)',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                    : Stack(
                      children: [
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length + (images.length < 5 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == images.length) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: InkWell(
                                  onTap: onPickImages,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: AppColors.primary,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'إضافة المزيد',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: FileImage(File(images[index].path)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: InkWell(
                                      onTap: () => onRemoveImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}

/// حقل نص عام بنمط النموذج الموحّد (أيقونة بادئة + حدود دائرية + التحقق
/// من عدم الفراغ).
class RentalAdTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  const RentalAdTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
      onChanged: onChanged,
    );
  }
}

/// قسم معلومات السيارة الأساسية (الماركة/الطراز/سنة الصنع/الحالة).
class RentalAdCarDetailsSection extends StatelessWidget {
  final ValueChanged<String> onMakeChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onYearChanged;
  final String condition;
  final ValueChanged<String?> onConditionChanged;

  const RentalAdCarDetailsSection({
    super.key,
    required this.onMakeChanged,
    required this.onModelChanged,
    required this.onYearChanged,
    required this.condition,
    required this.onConditionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RentalFormSectionLabel('معلومات السيارة'),
        const SizedBox(height: 8),
        RentalFormCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              RentalAdTextField(
                label: 'ماركة السيارة',
                icon: Icons.directions_car_rounded,
                onChanged: onMakeChanged,
              ),
              const SizedBox(height: 16),
              RentalAdTextField(
                label: 'طراز السيارة',
                icon: Icons.model_training_rounded,
                onChanged: onModelChanged,
              ),
              const SizedBox(height: 16),
              RentalAdTextField(
                label: 'سنة الصنع',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                onChanged: onYearChanged,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: condition,
                decoration: InputDecoration(
                  labelText: 'حالة السيارة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  prefixIcon: Icon(Icons.build_rounded, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                items: const [
                  DropdownMenuItem(value: 'used', child: Text('مستعمل')),
                  DropdownMenuItem(value: 'new', child: Text('جديد')),
                ],
                onChanged: onConditionChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// حقل سعر واحد (يومي أو شهري) — نفس نمط RentalAdTextField لكن بأيقونة
/// عملة وتحقق رقمي.
class RentalAdPriceField extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;

  const RentalAdPriceField({super.key, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        prefixIcon: Icon(Icons.attach_money_rounded, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        if (double.tryParse(value) == null) return 'أدخل رقمًا صحيحًا';
        return null;
      },
      onChanged: onChanged,
    );
  }
}

/// قسم أسعار التأجير (يومي + شهري) مع ملاحظة توضيحية.
class RentalAdPriceSection extends StatelessWidget {
  final ValueChanged<String> onDailyPriceChanged;
  final ValueChanged<String> onMonthlyPriceChanged;

  const RentalAdPriceSection({
    super.key,
    required this.onDailyPriceChanged,
    required this.onMonthlyPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RentalFormSectionLabel('أسعار التأجير'),
        const SizedBox(height: 8),
        RentalFormCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RentalAdPriceField(
                      label: 'السعر اليومي (ل.س)',
                      onChanged: onDailyPriceChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RentalAdPriceField(
                      label: 'السعر الشهري (ل.س)',
                      onChanged: onMonthlyPriceChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'سيتم عرض هذه الأسعار للمستأجرين المحتملين',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// حقل نص طويل عام (بلا حدود ظاهرة، أيقونة بادئة) — يُستخدم لشروط
/// التأجير، الموقع، والوصف.
class RentalAdMultilineField extends StatelessWidget {
  final String sectionLabel;
  final String hintLabel;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool required;

  const RentalAdMultilineField({
    super.key,
    required this.sectionLabel,
    required this.hintLabel,
    required this.icon,
    required this.onChanged,
    this.maxLines = 1,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RentalFormSectionLabel(sectionLabel),
        const SizedBox(height: 8),
        RentalFormCard(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: hintLabel,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(icon, color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: maxLines,
            validator:
                required
                    ? (value) {
                      if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
                      return null;
                    }
                    : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// زر نشر الإعلان أسفل النموذج.
class RentalAdSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  const RentalAdSubmitButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: const Text(
          'نشر الإعلان',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
