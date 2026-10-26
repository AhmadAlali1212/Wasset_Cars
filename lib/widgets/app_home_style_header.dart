import 'package:flutter/material.dart';
import 'package:mators_car/services/unread_notification_controller.dart';
import 'package:mators_car/screens/notifications/notifications_screen.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

/// رأس صفحة موحّد بنفس تصميم الشاشة الرئيسية بالضبط: جرس إشعارات (مع عداد
/// غير مقروء يُحدَّث دورياً)، عنوان بالمنتصف، أيقونة قائمة، وصندوق بحث
/// وظيفي حقيقي (onChanged فعلي، مو شكلي) — مع زر تصفية اختياري بجانب صندوق
/// البحث للصفحات التي تحتاجه.
class AppHomeStyleHeader extends StatefulWidget {
  final String title;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final VoidCallback? onFilterTap;

  const AppHomeStyleHeader({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearchChanged,
    this.searchHint = 'ابحث عن سيارة أو موديل...',
    this.onFilterTap,
  });

  @override
  State<AppHomeStyleHeader> createState() => _AppHomeStyleHeaderState();
}

class _AppHomeStyleHeaderState extends State<AppHomeStyleHeader> {
  final UnreadNotificationController _notifController =
      UnreadNotificationController.instance;

  @override
  void initState() {
    super.initState();
    // مصدر واحد مشترك بين كل الشاشات (بدل مؤقت وطلب منفصل بكل Header)
    _notifController.attach();
    _notifController.addListener(_onNotifCountChanged);
  }

  @override
  void dispose() {
    _notifController.removeListener(_onNotifCountChanged);
    _notifController.detach();
    super.dispose();
  }

  void _onNotifCountChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifCount = _notifController.unreadCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_outlined, size: 28),
                  if (unreadNotifCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                _notifController.refresh();
              },
            ),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu, size: 28),
              onPressed: () {
                AppSnackbar.showInfo(context, title: 'قائمة التنقل ستظهر في نسخة لاحقة');
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: widget.searchController,
                  textAlign: TextAlign.right,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon:
                        widget.searchController.text.isEmpty
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged('');
                              },
                            ),
                  ),
                ),
              ),
            ),
            if (widget.onFilterTap != null) ...[
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.black87),
                  onPressed: widget.onFilterTap,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
