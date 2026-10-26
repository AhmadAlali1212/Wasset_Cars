import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CarPhotosAndVideoStep extends StatelessWidget {
  final List<XFile> images;
  final List<XFile> videos;
  final int maxVideos;
  final int maxVideoSizeMb;
  final VoidCallback onPickImages;
  final VoidCallback onPickVideo;
  final void Function(int index) onRemoveVideo;

  const CarPhotosAndVideoStep({
    super.key,
    required this.images,
    required this.videos,
    required this.maxVideos,
    required this.maxVideoSizeMb,
    required this.onPickImages,
    required this.onPickVideo,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'اختر صور السيارة (حتى 5 صور)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('رفع الصور'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF0F4C81),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: GridView.builder(
              itemCount: images.isEmpty ? 1 : images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                if (images.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        'لم يتم اختيار صور بعد',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(images[index].path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'فيديو للسيارة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                '— حتى $maxVideos فيديو، $maxVideoSizeMb MB لكل واحد',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'يمكنك تخطّي هذه الخطوة تماماً ورفع الفيديو لاحقاً من شاشة تعديل السيارة.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: videos.length >= maxVideos ? null : onPickVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: Text(
              videos.isEmpty ? 'إضافة فيديو (اختياري)' : 'إضافة فيديو آخر',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (videos.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(videos.length, (index) {
              final video = videos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: Color(0xFF0F4C81)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(video.name, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => onRemoveVideo(index),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
