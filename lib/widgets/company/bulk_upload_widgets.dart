import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

/// ودجات وكلاسات بيانات استُخرجت من company_bulk_upload_screen.dart دون
/// أي تغيير بالتصميم أو المنطق — فقط أصبحت عامة (بدل خاصة بالملف) لتُنقل
/// لملف مستقل.

/// حالة رفع عنصر واحد ضمن دفعة الرفع الجماعي.
enum BatchUploadStatus { pending, uploading, success, failed }

/// سيارة واحدة داخل الدفعة المحلية قبل الرفع.
class BatchCarEntry {
  String make = '';
  String model = '';
  String year = '';
  String condition = 'مستعملة';
  String description = '';
  String priceText = '';
  String location = '';
  double? latitude;
  double? longitude;
  List<XFile> images = [];

  BatchUploadStatus status = BatchUploadStatus.pending;
  String? errorMessage;

  String get title {
    final t = '$make $model'.trim();
    return t.isEmpty ? 'سيارة جديدة' : t;
  }
}

/// حالة عدم وجود أي سيارات بالدفعة بعد.
class BulkUploadEmptyState extends StatelessWidget {
  const BulkUploadEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_filled_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              context.tr('no_cars_added'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('bulk_upload_empty_hint')}\n'
              '${context.tr('bulk_upload_empty_hint_second')}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة حالة الرفع (قيد الانتظار/جارٍ الرفع/نجح/فشل).
class BulkUploadStatusChip extends StatelessWidget {
  final BatchCarEntry entry;
  const BulkUploadStatusChip({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (entry.status) {
      case BatchUploadStatus.pending:
        color = Colors.grey;
        label = context.tr('pending_upload');
        break;
      case BatchUploadStatus.uploading:
        color = AppColors.primary;
        label = context.tr('uploading');
        break;
      case BatchUploadStatus.success:
        color = AppColors.success;
        label = context.tr('upload_success');
        break;
      case BatchUploadStatus.failed:
        color = AppColors.error;
        label = entry.errorMessage ?? context.tr('upload_failed');
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// بطاقة سيارة واحدة ضمن قائمة الدفعة (صورة مصغّرة + بيانات + شارة حالة
/// + قائمة إجراءات: تعديل/إعادة محاولة/حذف).
class BulkUploadEntryCard extends StatelessWidget {
  final BatchCarEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  const BulkUploadEntryCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                entry.images.isNotEmpty
                    ? Image.file(File(entry.images.first.path), width: 64, height: 64, fit: BoxFit.cover)
                    : Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.directions_car_outlined, color: Colors.grey),
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  entry.year.isNotEmpty ? '${entry.year} • ${entry.condition}' : entry.condition,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.priceText.trim().isNotEmpty
                      ? 'السعر: ${entry.priceText}'
                      : 'بدون سعر — ستُحفظ السيارة فقط',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                BulkUploadStatusChip(entry: entry),
              ],
            ),
          ),
          if (entry.status != BatchUploadStatus.uploading)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                } else if (value == 'retry') {
                  onRetry();
                }
              },
              itemBuilder:
                  (context) => [
                    if (entry.status != BatchUploadStatus.success)
                      PopupMenuItem(value: 'edit', child: Text(context.tr('edit'))),
                    if (entry.status == BatchUploadStatus.failed)
                      PopupMenuItem(value: 'retry', child: Text(context.tr('retry'))),
                    if (entry.status != BatchUploadStatus.success)
                      PopupMenuItem(value: 'delete', child: Text(context.tr('delete'))),
                  ],
            ),
        ],
      ),
    );
  }
}

/// منتقي صور نموذج إدخال سيارة الدفعة (صف أفقي: مربع إضافة + الصور
/// المختارة مع زر حذف لكل صورة).
class BatchImagesPicker extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onPickImages;
  final void Function(XFile image) onRemoveImage;

  const BatchImagesPicker({
    super.key,
    required this.images,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: onPickImages,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey),
                color: AppColors.surfaceLight,
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
            ),
          ),
          ...images.map(
            (img) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(img.path), width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(img),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
