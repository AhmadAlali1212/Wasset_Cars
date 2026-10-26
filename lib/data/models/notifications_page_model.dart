import 'package:mators_car/data/models/notification_model.dart';

// نتيجة صفحة واحدة من الإشعارات (لدعم التحميل التدريجي / pagination)
class NotificationsPage {
  final List<AppNotification> items;
  final bool hasMore;
  final int nextPage;
  final int unreadCount;

  NotificationsPage({
    required this.items,
    required this.hasMore,
    required this.nextPage,
    required this.unreadCount,
  });
}
