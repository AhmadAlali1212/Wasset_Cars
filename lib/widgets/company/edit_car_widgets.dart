import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

/// ودجات استُخرجت من دوال _build... الخاصة بشاشة تعديل السيارة
/// (edit_car_screen.dart) دون أي تغيير بالتصميم أو المنطق.

/// تسمية حقل موحّدة أعلى كل عنصر إدخال بالنموذج.
class EditCarFieldLabel extends StatelessWidget {
  final String text;
  const EditCarFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black54)),
    );
  }
}

/// مربّع "إضافة صورة" مربّع الشكل يفتح منتقي الصور عند الضغط.
class EditCarAddImageTile extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const EditCarAddImageTile({super.key, required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.add_a_photo_outlined, color: accentColor),
      ),
    );
  }
}

/// محرّر صور السيارة: يعرض إما الصور الجديدة المختارة محلياً (مع إمكانية
/// حذف كل واحدة وإضافة المزيد)، أو الصورة الحالية من السيرفر مع زر
/// لتغييرها إن لم تُختر صور جديدة بعد.
class EditCarImagesEditor extends StatelessWidget {
  final List<XFile> newImages;
  final int maxImages;
  final String? primaryImageUrl;
  final VoidCallback onPickImages;
  final void Function(int index) onRemoveNewImage;
  final Color accentColor;

  const EditCarImagesEditor({
    super.key,
    required this.newImages,
    required this.maxImages,
    required this.primaryImageUrl,
    required this.onPickImages,
    required this.onRemoveNewImage,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // إذا اختار المستخدم صوراً جديدة، نعرضها بدل الصورة القديمة من السيرفر
    if (newImages.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditCarFieldLabel('الصور الجديدة (${newImages.length}/$maxImages) — ستستبدل الصور الحالية'),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: newImages.length + (newImages.length < maxImages ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == newImages.length) {
                  return EditCarAddImageTile(onTap: onPickImages, accentColor: accentColor);
                }
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(newImages[index].path), width: 110, height: 110, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveNewImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    // لا صور جديدة بعد: نعرض الصورة الحالية من السيرفر مع زر لتغييرها
    return GestureDetector(
      onTap: onPickImages,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              primaryImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: primaryImageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (_, __) => Container(color: const Color(0xFFE9ECF2)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFE9ECF2),
                        child: const Icon(Icons.directions_car, size: 48, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFE9ECF2),
                      child: const Icon(Icons.directions_car, size: 48, color: Colors.grey),
                    ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('تغيير الصور', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// محرّر فيديوهات السيارة: قائمة الفيديوهات الحالية (مع حذف مباشر لكل
/// واحد) وزر إضافة فيديو جديد (حتى الحد الأقصى المسموح).
class EditCarVideosEditor extends StatelessWidget {
  final List<String> existingVideos;
  final int maxVideos;
  final String? removingVideoUrl;
  final bool isUploadingVideo;
  final void Function(String videoUrl) onRemoveVideo;
  final VoidCallback onPickAndUploadVideo;
  final Color accentColor;

  const EditCarVideosEditor({
    super.key,
    required this.existingVideos,
    required this.maxVideos,
    required this.removingVideoUrl,
    required this.isUploadingVideo,
    required this.onRemoveVideo,
    required this.onPickAndUploadVideo,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [EditCarFieldLabel('فيديوهات السيارة (${existingVideos.length}/$maxVideos)')]),
        if (existingVideos.isNotEmpty)
          ...existingVideos.map((videoUrl) {
            final isRemoving = removingVideoUrl == videoUrl;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF6F8FB), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.videocam, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(videoUrl.split('/').last, overflow: TextOverflow.ellipsis)),
                  isRemoving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => onRemoveVideo(videoUrl),
                        ),
                ],
              ),
            );
          }),
        if (existingVideos.length < maxVideos)
          OutlinedButton.icon(
            onPressed: isUploadingVideo ? null : onPickAndUploadVideo,
            icon: isUploadingVideo
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.videocam_outlined),
            label: Text(existingVideos.isEmpty ? 'إضافة فيديو (اختياري)' : 'إضافة فيديو آخر'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }
}
