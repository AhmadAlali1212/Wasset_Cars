import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mators_car/data/models/notification_model.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/services/controllers/auction_service.dart';
import 'package:mators_car/services/controllers/notification_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/screens/ratings/pending_ratings_screen.dart';
import 'package:mators_car/screens/messages/chat_thread_screen.dart';
import 'package:mators_car/screens/disputes/my_disputes_screen.dart';
import 'package:mators_car/screens/auction/auction_detail_screen.dart';
import 'package:mators_car/data/models/auction_model.dart';
import 'package:mators_car/widgets/notifications/notifications_screen_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

// ترتيب التبويبات كما في التصميم المرجعي (الكل/المزادات/الطلبات/العروض/النظام)
// null == كل الإشعارات بدون فلترة
const List<NotificationTabItem> _tabs = [
  NotificationTabItem(null, 'الكل'),
  NotificationTabItem(NotificationCategory.auction, 'المزادات'),
  NotificationTabItem(NotificationCategory.order, 'الطلبات'),
  NotificationTabItem(NotificationCategory.offer, 'العروض'),
  NotificationTabItem(NotificationCategory.system, 'النظام'),
];

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  final AuctionService _auctionService = AuctionService();
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
      final freshOnes =
          page.items.where((n) => !existingIds.contains(n.id)).toList();
      if (freshOnes.isEmpty) return;
      setState(() {
        _items.insertAll(0, freshOnes);
      });
      AppSnackbar.showInfo(
        context,
        title:
            freshOnes.length == 1
                ? 'لديك إشعار جديد: ${freshOnes.first.title}'
                : 'لديك ${freshOnes.length} إشعارات جديدة',
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

  // ⬅️ جديد: تسمية زر الانتقال المباشر حسب نوع الإشعار، أو null إن لم
  // يكن لهذا النوع وجهة محددة (يبقى bottom sheet بدون زر انتقال).
  String? _deepLinkLabel(String rawType) {
    switch (rawType) {
      case 'new_bid':
      case 'bid_outbid':
      case 'auction_ending_soon':
      case 'auction_sale_completed':
        return 'فتح المزاد';
      case 'new_message':
        return 'فتح المحادثة';
      case 'dispute_raised':
      case 'dispute_needs_review':
      case 'dispute_resolved':
        return 'عرض النزاع';
      default:
        return null;
    }
  }

  Future<void> _openDeepLink(AppNotification notification) async {
    switch (notification.rawType) {
      case 'new_bid':
      case 'bid_outbid':
      case 'auction_ending_soon':
      case 'auction_sale_completed':
        await _openAuction(notification.data['auction_id']);
        return;
      case 'new_message':
        final senderId = int.tryParse(
          '${notification.data['sender_id'] ?? ''}',
        );
        if (senderId == null) return;
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ChatThreadScreen(
                  partnerId: senderId,
                  partnerName: 'محادثة',
                ),
          ),
        );
        return;
      case 'dispute_raised':
      case 'dispute_needs_review':
      case 'dispute_resolved':
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyDisputesScreen()),
        );
        return;
    }
  }

  Future<void> _openAuction(dynamic rawAuctionId) async {
    final auctionId = int.tryParse('${rawAuctionId ?? ''}');
    if (auctionId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final json = await _auctionService.getAuctionDetails(auctionId);
      if (!mounted) return;
      Navigator.pop(context); // إغلاق مؤشر التحميل
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuctionDetailScreen(auction: Auction.fromJson(json)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.showError(
        context,
        title: 'تعذّر فتح المزاد',
        debugMessage: e,
      );
    }
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
                  NotificationIconBadge(visual: visual, size: 46),
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
              // ⬅️ جديد: إشعار "يمكنك الآن تقييم..." يأخذ مباشرة لشاشة
              // "تقييمات معلّقة" بدل ترك المستخدم يبحث عنها بنفسه.
              if (notification.rawType == 'ratable_transaction') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PendingRatingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.star_border,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'قيّم الآن',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
              // ⬅️ جديد: deep-linking لباقي أنواع الإشعارات (كان مقتصراً
              // على "تقييمات معلّقة" فقط، وباقي الأنواع تكتفي بعرض bottom
              // sheet بدون أي وجهة فعلية).
              if (_deepLinkLabel(notification.rawType) != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openDeepLink(notification);
                    },
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      _deepLinkLabel(notification.rawType)!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
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
      AppSnackbar.showError(
        context,
        title: 'تعذّر تعليم الإشعارات كمقروءة',
        subtitle: e is ApiException ? e.message : null,
        debugMessage: e,
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

  Widget _buildTabsBar() => NotificationTabsBar(
    tabs: _tabs,
    selectedCategory: _selectedCategory,
    onSelect: (category) {
      setState(() => _selectedCategory = category);
      _autoFillAttempts = 0;
      _maybeAutoFill();
    },
  );

  Widget _buildBody(List<AppNotification> visibleItems) {
    if (_isLoading) {
      return const SkeletonList(itemCount: 8);
    }
    if (_errorMessage != null) {
      return NotificationsErrorState(
        message: _errorMessage!,
        onRetry: _loadFirstPage,
      );
    }
    if (visibleItems.isEmpty) {
      return NotificationsEmptyState(onRefresh: _loadFirstPage);
    }

    final sections = _groupByDate(visibleItems);

    return NotificationsGroupedList(
      scrollController: _scrollController,
      sections: sections,
      isLoadingMore: _isLoadingMore,
      onRefresh: _loadFirstPage,
      visualFor: _visualFor,
      onTapNotification: _handleTap,
    );
  }

  List<NotificationDateGroup> _groupByDate(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final map = <String, NotificationDateGroup>{};
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
      map.putIfAbsent(label, () => NotificationDateGroup(label)).items.add(n);
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

  NotificationVisualStyle _visualFor(AppNotification notification) {
    final text =
        '${notification.rawType} ${notification.title} ${notification.body}'
            .toLowerCase();

    bool has(List<String> words) => words.any((w) => text.contains(w));

    if (has(['accept', 'قبول', 'فاز', 'won', 'approved', 'موافق'])) {
      return const NotificationVisualStyle(
        icon: Icons.check_circle,
        color: Color(0xFF22C55E),
        bgColor: Color(0xFFE7F8EE),
      );
    }
    if (has(['auction ended', 'انتهى المزاد', 'انتهت', 'closed'])) {
      return const NotificationVisualStyle(
        icon: Icons.gavel_rounded,
        color: Color(0xFF6D5DD3),
        bgColor: Color(0xFFEDEBFB),
      );
    }
    if (has(['wallet', 'إيداع', 'محفظة', 'رصيد', 'deposit'])) {
      return const NotificationVisualStyle(
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFF2563EB),
        bgColor: Color(0xFFE8F0FE),
      );
    }
    if (notification.category == NotificationCategory.offer) {
      return const NotificationVisualStyle(
        icon: Icons.local_offer_rounded,
        color: Color(0xFFDC2626),
        bgColor: Color(0xFFFCE8E8),
      );
    }
    if (has(['review', 'مراجعة', 'قيد', 'pending'])) {
      return const NotificationVisualStyle(
        icon: Icons.access_time_filled_rounded,
        color: Color(0xFFF59E0B),
        bgColor: Color(0xFFFEF3E2),
      );
    }
    if (has(['subscription', 'اشتراك'])) {
      return const NotificationVisualStyle(
        icon: Icons.verified_user_rounded,
        color: Color(0xFF16A34A),
        bgColor: Color(0xFFE7F8EE),
      );
    }
    if (has(['support', 'دعم', 'message', 'رسالة', 'chat'])) {
      return const NotificationVisualStyle(
        icon: Icons.chat_bubble_rounded,
        color: Color(0xFF334155),
        bgColor: Color(0xFFEAECEF),
      );
    }
    if (notification.category == NotificationCategory.auction) {
      return const NotificationVisualStyle(
        icon: Icons.gavel_rounded,
        color: Color(0xFF6D5DD3),
        bgColor: Color(0xFFEDEBFB),
      );
    }
    if (notification.category == NotificationCategory.order) {
      return const NotificationVisualStyle(
        icon: Icons.receipt_long_rounded,
        color: Color(0xFF2563EB),
        bgColor: Color(0xFFE8F0FE),
      );
    }
    return const NotificationVisualStyle(
      icon: Icons.notifications_rounded,
      color: Color(0xFF64748B),
      bgColor: Color(0xFFEEF1F4),
    );
  }
}
