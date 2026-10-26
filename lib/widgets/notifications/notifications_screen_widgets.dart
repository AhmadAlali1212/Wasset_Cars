import 'package:flutter/material.dart';
import 'package:mators_car/data/models/notification_model.dart';
import 'package:mators_car/ulits/colors.dart';

/// ودجات وكلاسات بيانات استُخرجت من notifications_screen.dart دون أي
/// تغيير بالتصميم أو المنطق — فقط أصبحت عامة (بدل خاصة بالملف) لتُنقل
/// لملف مستقل.

/// عنصر تبويب واحد أعلى شاشة الإشعارات (مثال: "الكل"، "المزادات"...).
class NotificationTabItem {
  final NotificationCategory? category;
  final String label;
  const NotificationTabItem(this.category, this.label);
}

/// مجموعة إشعارات تابعة ليوم واحد (بعنوان "اليوم"، "أمس"، أو تاريخ كامل).
class NotificationDateGroup {
  final String label;
  final List<AppNotification> items = [];
  NotificationDateGroup(this.label);
}

/// وصف الشكل البصري لإشعار حسب نوعه (أيقونة/لون رئيسي/لون خلفية).
class NotificationVisualStyle {
  final IconData icon;
  final Color color;
  final Color bgColor;
  const NotificationVisualStyle({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

/// أيقونة الإشعار الدائرية الملوّنة.
class NotificationIconBadge extends StatelessWidget {
  final NotificationVisualStyle visual;
  final double size;
  const NotificationIconBadge({super.key, required this.visual, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visual.bgColor,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(visual.icon, color: visual.color, size: size * 0.5),
    );
  }
}

/// عنصر إشعار واحد داخل القائمة (أيقونة + عنوان + نص + الوقت النسبي).
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final NotificationVisualStyle visual;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.visual,
    required this.onTap,
  });

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                NotificationIconBadge(visual: visual),
                if (!notification.isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: visual.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          notification.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريط التبويبات الأفقي أعلى شاشة الإشعارات.
class NotificationTabsBar extends StatelessWidget {
  final List<NotificationTabItem> tabs;
  final NotificationCategory? selectedCategory;
  final ValueChanged<NotificationCategory?> onSelect;

  const NotificationTabsBar({
    super.key,
    required this.tabs,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              tabs.map((tab) {
                final isSelected = selectedCategory == tab.category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    onTap: () => onSelect(tab.category),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            width: 28,
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

/// حالة خطأ تحميل الإشعارات (فشل الاتصال) مع زر إعادة محاولة.
class NotificationsErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const NotificationsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ),
      ],
    );
  }
}

/// حالة عدم وجود أي إشعارات ضمن التبويب الحالي.
class NotificationsEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const NotificationsEmptyState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد إشعارات هنا حالياً',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

/// القائمة الرئيسية للإشعارات مقسّمة حسب اليوم، مع مؤشر تحميل عند نهايتها
/// أثناء جلب المزيد (تمرير لانهائي).
class NotificationsGroupedList extends StatelessWidget {
  final ScrollController scrollController;
  final List<NotificationDateGroup> sections;
  final bool isLoadingMore;
  final Future<void> Function() onRefresh;
  final NotificationVisualStyle Function(AppNotification) visualFor;
  final void Function(AppNotification) onTapNotification;

  const NotificationsGroupedList({
    super.key,
    required this.scrollController,
    required this.sections,
    required this.isLoadingMore,
    required this.onRefresh,
    required this.visualFor,
    required this.onTapNotification,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: sections.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= sections.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  section.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < section.items.length; i++) ...[
                      NotificationTile(
                        notification: section.items[i],
                        visual: visualFor(section.items[i]),
                        onTap: () => onTapNotification(section.items[i]),
                      ),
                      if (i != section.items.length - 1)
                        Divider(height: 1, indent: 78, color: Colors.grey.shade100),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
