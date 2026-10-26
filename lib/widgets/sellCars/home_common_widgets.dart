import 'package:flutter/material.dart';

/// ودجت مشتركة صغيرة كانت مضمّنة كميثودات خاصة (_build...) داخل ملف
/// home_ads_screen.dart الضخم — استُخرجت هنا كـ StatelessWidget مستقلة
/// حتى يصبح المشروع أكثر تنظيماً (كل ودجت بمكانها الخاص بدل تكديس آلاف
/// الأسطر بملف واحد)، ولإتاحة إعادة استخدامها من شاشات أخرى مستقبلاً.

/// صندوق رسالة فارغة/تنبيهية بسيط (مثال: "لا توجد نتائج مطابقة")
class EmptyHint extends StatelessWidget {
  final String message;
  const EmptyHint(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }
}

/// عنوان قسم مع رابط "عرض الكل" (يُستخدم فوق كل قائمة أفقية بالشاشة الرئيسية)
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const HomeSectionHeader({super.key, required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            'عرض الكل',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// شارة صغيرة (أيقونة + نص) تُستخدم بتفاصيل بطاقة السيارة (سنة، ممشى، إلخ)
class DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const DetailChip(this.icon, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// نقاط مؤشر الصفحة الحالية (تُستخدم تحت PageView السيارات المميّزة)
class PageDotsIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  const PageDotsIndicator({super.key, required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == currentIndex ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: index == currentIndex ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}

/// شريط تنبيه "لا يوجد اتصال بالإنترنت — يتم عرض آخر بيانات محفوظة"
class OfflineBanner extends StatelessWidget {
  final DateTime? cachedAt;
  final VoidCallback onRetry;

  const OfflineBanner({super.key, required this.cachedAt, required this.onRetry});

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final agoText = cachedAt == null ? '' : ' (${_formatRelativeTime(cachedAt!)})';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'لا يوجد اتصال بالإنترنت — يتم عرض آخر بيانات محفوظة$agoText',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// مؤشر أسفل قائمة قابلة للتمرير اللانهائي (Infinite Scroll): دائرة تحميل
/// أثناء جلب الصفحة التالية، أو رسالة "لا مزيد من السيارات" عند آخر صفحة
class LoadMoreFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMorePages;
  final bool showEndMessage;

  const LoadMoreFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMorePages,
    this.showEndMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!hasMorePages && showEndMessage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('لا مزيد من السيارات', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
