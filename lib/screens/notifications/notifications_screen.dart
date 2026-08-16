import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mators_car/models/notification_model.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/services/notification_service.dart';
import 'package:mators_car/ulits/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

// ترتيب التبويبات كما في التصميم المرجعي (الكل/المزادات/الطلبات/العروض/النظام)
// null == كل الإشعارات بدون فلترة
const List<_TabItem> _tabs = [
  _TabItem(null, 'الكل'),
  _TabItem(NotificationCategory.auction, 'المزادات'),
  _TabItem(NotificationCategory.order, 'الطلبات'),
  _TabItem(NotificationCategory.offer, 'العروض'),
  _TabItem(NotificationCategory.system, 'النظام'),
];

class _TabItem {
  final NotificationCategory? category;
  final String label;
  const _TabItem(this.category, this.label);
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  final ScrollController _scrollController = ScrollController();

  final List<AppNotification> _items = [];
  NotificationCategory? _selectedCategory;
  bool _unreadOnly = false;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _nextPage = 1;
  String? _errorMessage;

  // فلترة الفئة (النظام/العروض/...) تتم محلياً بعد الجلب، لأن السيرفر
  // يفلتر بالتطابق الحرفي لعمود type وقيمه غير موثّقة. لذلك عند اختيار
  // تبويب معيّن مع وجود صفحات أخرى في السيرفر، نواصل تحميل الصفحات
  // تلقائياً في الخلفية حتى تمتلئ النتائج المعروضة أو تنفد الصفحات.
  int _autoFillAttempts = 0;
  static const int _autoFillMaxAttempts = 6;
  static const int _autoFillTarget = 8;

  // تحديث دوري بالخلفية لجلب الإشعارات الجديدة تلقائياً أثناء بقاء
  // المستخدم على الشاشة (بديل عملي عن الإشعارات الفورية push، والتي
  // تتطلب ربط Firebase Cloud Messaging على مستوى المشروع الأصلي —
  // خارج نطاق هذا الملف).
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _pollForNewNotifications(),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  // يفحص وجود إشعارات جديدة لم تُعرض بعد ويضيفها لأعلى القائمة، دون
  // إزعاج المستخدم بمؤشر تحميل أو فقدان مكان التمرير.
  Future<void> _pollForNewNotifications() async {
    if (!mounted || _isLoading) return;
    try {
      final page = await _service.getNotifications(
        page: 1,
        status: _unreadOnly ? 'unread' : null,
      );
      if (!mounted) return;
      final existingIds = _items.map((n) => n.id).toSet();
      final freshOnes = page.items
          .where((n) => !existingIds.contains(n.id))
          .toList();
      if (freshOnes.isEmpty) return;
      setState(() {
        _items.insertAll(0, freshOnes);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            freshOnes.length == 1
                ? 'لديك إشعار جديد: ${freshOnes.first.title}'
                : 'لديك ${freshOnes.length} إشعارات جديدة',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // فشل صامت لتحديث خلفي، لا داعي لإزعاج المستخدم بخطأ شبكة عابر
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    _autoFillAttempts = 0;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await _service.getNotifications(
        page: 1,
        status: _unreadOnly ? 'unread' : null,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _nextPage = page.nextPage;
        _isLoading = false;
      });
      _maybeAutoFill();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is ApiException ? e.message : 'تعذر تحميل الإشعارات';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service.getNotifications(
        page: _nextPage,
        status: _unreadOnly ? 'unread' : null,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _hasMore = page.hasMore;
        _nextPage = page.nextPage;
        _isLoadingMore = false;
      });
      _maybeAutoFill();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  // يواصل جلب الصفحات التالية تلقائياً إذا كان تبويب فئة معيّن مختاراً
  // وعدد النتائج المطابقة المعروضة قليلاً، بدل ترك المستخدم يمرّر يدوياً
  // عبر صفحات لا تحتوي على نتائج من الفئة المختارة.
  void _maybeAutoFill() {
    if (_selectedCategory == null) return;
    if (!_hasMore || _isLoadingMore) return;
    if (_autoFillAttempts >= _autoFillMaxAttempts) return;
    if (_filteredItems.length >= _autoFillTarget) return;
    _autoFillAttempts++;
    _loadMore();
  }

  Future<void> _handleTap(AppNotification notification) async {
    if (!notification.isRead) {
      final index = _items.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        setState(() {
          _items[index] = notification.copyWith(readAt: DateTime.now());
        });
      }
      try {
        await _service.markAsRead(notification.id);
      } catch (_) {
        // إبقاء الحالة كمقروءة محلياً حتى لو فشل الطلب مؤقتاً
      }
    }
    if (!mounted) return;
    _showDetails(notification);
  }

  void _showDetails(AppNotification notification) {
    final visual = _visualFor(notification);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                children: [
                  _IconBadge(visual: visual, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                notification.body.isNotEmpty
                    ? notification.body
                    : 'لا يوجد نص إضافي لهذا الإشعار.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _formatFullDate(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    final unread = _items.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    final previous = List<AppNotification>.from(_items);
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (!_items[i].isRead) {
          _items[i] = _items[i].copyWith(readAt: DateTime.now());
        }
      }
    });
    try {
      await _service.markAllAsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(previous);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'تعذر تعليم الإشعارات كمقروءة',
          ),
        ),
      );
    }
  }

  List<AppNotification> get _filteredItems {
    if (_selectedCategory == null) return _items;
    return _items.where((n) => n.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _unreadOnly ? 'عرض الكل' : 'غير المقروءة فقط',
            icon: Icon(
              _unreadOnly
                  ? Icons.mark_email_unread
                  : Icons.mark_email_unread_outlined,
              color: _unreadOnly ? AppColors.primary : Colors.black54,
            ),
            onPressed: () {
              setState(() => _unreadOnly = !_unreadOnly);
              _loadFirstPage();
            },
          ),
          IconButton(
            tooltip: 'تعليم الكل كمقروء',
            icon: const Icon(Icons.done_all, color: Colors.black54),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabsBar(),
          const Divider(height: 1),
          Expanded(child: _buildBody(visibleItems)),
        ],
      ),
    );
  }

  Widget _buildTabsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            final isSelected = _selectedCategory == tab.category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedCategory = tab.category);
                  _autoFillAttempts = 0;
                  _maybeAutoFill();
                },
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
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 2.5,
                        width: 28,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
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

  Widget _buildBody(List<AppNotification> visibleItems) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: _loadFirstPage,
              child: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }
    if (visibleItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
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

    final sections = _groupByDate(visibleItems);

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: sections.length + (_isLoadingMore ? 1 : 0),
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
                      _NotificationTile(
                        notification: section.items[i],
                        visual: _visualFor(section.items[i]),
                        onTap: () => _handleTap(section.items[i]),
                      ),
                      if (i != section.items.length - 1)
                        Divider(
                          height: 1,
                          indent: 78,
                          color: Colors.grey.shade100,
                        ),
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

  List<_DateSection> _groupByDate(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final map = <String, _DateSection>{};
    for (final n in items) {
      final d = n.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      String label;
      if (day == today) {
        label = 'اليوم';
      } else if (day == yesterday) {
        label = 'أمس';
      } else {
        label = _formatFullDate(d);
      }
      map.putIfAbsent(label, () => _DateSection(label)).items.add(n);
    }
    return map.values.toList();
  }

  String _formatFullDate(DateTime d) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  _NotificationVisual _visualFor(AppNotification notification) {
    final text =
        '${notification.rawType} ${notification.title} ${notification.body}'
            .toLowerCase();

    bool has(List<String> words) => words.any((w) => text.contains(w));

    if (has(['accept', 'قبول', 'فاز', 'won', 'approved', 'موافق'])) {
      return const _NotificationVisual(
        icon: Icons.check_circle,
        color: Color(0xFF22C55E),
        bgColor: Color(0xFFE7F8EE),
      );
    }
    if (has(['auction ended', 'انتهى المزاد', 'انتهت', 'closed'])) {
      return const _NotificationVisual(
        icon: Icons.gavel_rounded,
        color: Color(0xFF6D5DD3),
        bgColor: Color(0xFFEDEBFB),
      );
    }
    if (has(['wallet', 'إيداع', 'محفظة', 'رصيد', 'deposit'])) {
      return const _NotificationVisual(
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFF2563EB),
        bgColor: Color(0xFFE8F0FE),
      );
    }
    if (notification.category == NotificationCategory.offer) {
      return const _NotificationVisual(
        icon: Icons.local_offer_rounded,
        color: Color(0xFFDC2626),
        bgColor: Color(0xFFFCE8E8),
      );
    }
    if (has(['review', 'مراجعة', 'قيد', 'pending'])) {
      return const _NotificationVisual(
        icon: Icons.access_time_filled_rounded,
        color: Color(0xFFF59E0B),
        bgColor: Color(0xFFFEF3E2),
      );
    }
    if (has(['subscription', 'اشتراك'])) {
      return const _NotificationVisual(
        icon: Icons.verified_user_rounded,
        color: Color(0xFF16A34A),
        bgColor: Color(0xFFE7F8EE),
      );
    }
    if (has(['support', 'دعم', 'message', 'رسالة', 'chat'])) {
      return const _NotificationVisual(
        icon: Icons.chat_bubble_rounded,
        color: Color(0xFF334155),
        bgColor: Color(0xFFEAECEF),
      );
    }
    if (notification.category == NotificationCategory.auction) {
      return const _NotificationVisual(
        icon: Icons.gavel_rounded,
        color: Color(0xFF6D5DD3),
        bgColor: Color(0xFFEDEBFB),
      );
    }
    if (notification.category == NotificationCategory.order) {
      return const _NotificationVisual(
        icon: Icons.receipt_long_rounded,
        color: Color(0xFF2563EB),
        bgColor: Color(0xFFE8F0FE),
      );
    }
    return const _NotificationVisual(
      icon: Icons.notifications_rounded,
      color: Color(0xFF64748B),
      bgColor: Color(0xFFEEF1F4),
    );
  }
}

class _DateSection {
  final String label;
  final List<AppNotification> items = [];
  _DateSection(this.label);
}

class _NotificationVisual {
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _IconBadge extends StatelessWidget {
  final _NotificationVisual visual;
  final double size;
  const _IconBadge({required this.visual, this.size = 50});

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

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final _NotificationVisual visual;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.visual,
    required this.onTap,
  });

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
                  _IconBadge(visual: visual),
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
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.bold,
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
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.day}/${date.month}/${date.year}';
  }
}
