import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/car_model.dart';
import 'package:mators_car/data/models/rating_model.dart';
import 'package:mators_car/services/controllers/follow_service.dart';
import 'package:mators_car/services/controllers/company_service.dart';
import 'package:mators_car/services/controllers/rating_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/constant.dart';
import 'package:mators_car/ulits/contact_launcher.dart';
import 'package:mators_car/screens/messages/chat_thread_screen.dart';
import 'package:mators_car/widgets/common/report_user_sheet.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/company/company_public_profile_widgets.dart';

// شاشة الملف العام لشركة/معرض. لا يوجد بالـ API endpoint مخصص لجلب "ملف
// شركة واحدة بكل تفاصيلها" (فقط متابعة/حالة متابعة/قائمة المتابَعين)،
// لذلك تُبنى من أي بيانات شركة متوفرة أصلاً (من قائمة المتابَعين، أو من
// بيانات المالك المضمّنة بإعلان سيارة)، وتُستكمل بجلب سيارات الشركة
// وحالة المتابعة الحقيقية من السيرفر.
class CompanyPublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> company;

  const CompanyPublicProfileScreen({super.key, required this.company});

  @override
  State<CompanyPublicProfileScreen> createState() =>
      _CompanyPublicProfileScreenState();
}

class _CompanyPublicProfileScreenState
    extends State<CompanyPublicProfileScreen> {
  final FollowService _followService = FollowService();
  final CompanyService _companyService = CompanyService();
  final RatingService _ratingService = RatingService();

  bool? _isFollowing;
  bool _isActingOnFollow = false;
  bool _isOwnProfile = false;
  late Future<List<Car>> _companyCarsFuture;
  late Future<List<Rating>> _ratingsFuture;

  int get _companyId =>
      int.tryParse('${widget.company['id'] ?? widget.company['user_id']}') ?? 0;

  String get _companyName =>
      (widget.company['name'] ??
              widget.company['company_name'] ??
              'اسم غير معروف')
          .toString();

  String? get _logoUrl => AppConstants.resolveImageUrl(
    widget.company['logo'] ??
        widget.company['profile_image'] ??
        widget.company['avatar'] ??
        widget.company['image'],
  );

  String? get _coverUrl => AppConstants.resolveImageUrl(
    widget.company['cover_image'] ?? widget.company['cover'],
  );

  bool get _isVerified {
    final v = widget.company['verified'] ?? widget.company['is_verified'];
    return v == true || v?.toString() == '1' || v?.toString() == 'true';
  }

  String get _location =>
      (widget.company['city'] ??
              widget.company['location'] ??
              widget.company['address'] ??
              '')
          .toString();

  String? get _companyPhone {
    final p =
        widget.company['phone_number'] ??
        widget.company['phone'] ??
        widget.company['whatsapp'];
    if (p == null || p.toString().trim().isEmpty) return null;
    return p.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadOwnershipAndFollowStatus();
    _companyCarsFuture = _loadCompanyCars();
    _ratingsFuture = _loadRatings();
  }

  // لا معنى لزر "متابعة" أو "رسالة" على ملفك الشخصي أنت نفسك، ولا يجوز
  // أصلاً استدعاء GET /companies/{id}/follow-status عن نفسك، لذلك نتحقق
  // من هوية المستخدم الحالي أولاً قبل أي استدعاء متعلق بالمتابعة.
  Future<void> _loadOwnershipAndFollowStatus() async {
    final user = await AuthStorage.getUser();
    final myId = int.tryParse('${user?['id'] ?? ''}');
    final isOwn = myId != null && _companyId != 0 && myId == _companyId;
    if (!mounted) return;
    setState(() => _isOwnProfile = isOwn);
    if (!isOwn) _loadFollowStatus();
  }

  Future<List<Rating>> _loadRatings() async {
    if (_companyId == 0) return [];
    try {
      final raw = await _ratingService.getRatings(_companyId);
      return raw.map((json) => Rating.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  // ملاحظة مهمة: setState(() => _ratingsFuture = _loadRatings()) كانت
  // تسبب الخطأ "setState() callback argument returned a Future" لأن
  // تعبير الإسناد "متغير = دالة_غير_متزامنة()" بصيغة السهم => يُقيَّم
  // إلى قيمة الإسناد نفسها (أي الـ Future المُرجعة)، فيظن Flutter أن
  // الكولباك نفسه "غير متزامن" ويرفضه وقت التشغيل. استخدام جسم بأقواس {}
  // يجعل الكولباك يُرجع void بدل قيمة الإسناد، فيحل المشكلة نهائياً.
  void _refreshRatings() {
    setState(() {
      _ratingsFuture = _loadRatings();
    });
  }

  Future<void> _loadFollowStatus() async {
    if (_companyId == 0) return;
    try {
      final following = await _followService.isFollowing(_companyId);
      if (!mounted) return;
      setState(() => _isFollowing = following);
    } catch (_) {
      // نتجاهل الفشل، الزر بيبقى بحالة "متابعة" الافتراضية
    }
  }

  Future<List<Car>> _loadCompanyCars() async {
    if (_companyId == 0) return [];
    try {
      final cars = await _companyService.getOtherUsersCars();
      return cars
          .where((c) => int.tryParse('${c['user_id']}') == _companyId)
          .map((json) => Car.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _toggleFollow() async {
    if (_companyId == 0 || _isActingOnFollow) return;
    setState(() => _isActingOnFollow = true);
    final wasFollowing = _isFollowing ?? false;
    try {
      if (wasFollowing) {
        await _followService.unfollowCompany(_companyId);
      } else {
        await _followService.followCompany(_companyId);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !wasFollowing;
        _isActingOnFollow = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isActingOnFollow = false);
      AppSnackbar.showError(
        context,
        title: 'تعذّر تنفيذ الطلب',
        subtitle: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isActingOnFollow = false);
      AppSnackbar.showError(
        context,
        title: 'تعذّر تنفيذ الطلب',
        debugMessage: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // ⬅️ جديد: إبلاغ عن هذا الحساب مباشرة من صفحته العامة
              if (!_isOwnProfile)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'report') {
                      ReportUserSheet.show(
                        context,
                        reportedUserId: _companyId,
                        contextType: 'ad',
                      );
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: 'report',
                          child: Text('إبلاغ / حظر'),
                        ),
                      ],
                )
              else
                const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  _coverUrl != null
                      ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: _coverUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder:
                                (_, __) => Container(color: AppColors.primary),
                            errorWidget:
                                (_, __, ___) =>
                                    Container(color: AppColors.primary),
                          ),
                          // تدرّج خفيف أسفل الغلاف لتحسين تباين أي عناصر
                          // فوقه ولإضافة عمق بصري بدل لون مسطح بالكامل
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.25),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                          ),
                        ),
                      ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    _logoUrl != null
                                        ? CachedNetworkImage(
                                          imageUrl: _logoUrl!,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 168,
                                          placeholder:
                                              (_, __) => const Icon(
                                                Icons.storefront,
                                                size: 38,
                                              ),
                                          errorWidget:
                                              (_, __, ___) => const Icon(
                                                Icons.storefront,
                                                size: 38,
                                              ),
                                        )
                                        : const Icon(
                                          Icons.storefront,
                                          size: 38,
                                          color: AppColors.primary,
                                        ),
                              ),
                            ),
                            // شارة التوثيق كطبقة صغيرة على حافة الصورة بدل
                            // أيقونة منفصلة بجانب الاسم — أوضح وأكثر احترافية
                            if (_isVerified)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _companyName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'معرض سيارات',
                                style: TextStyle(color: Colors.black54),
                              ),
                              if (_location.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.black45,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              _buildStatsRow(),
                              if ((widget.company['description'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Text(
                                  widget.company['description'].toString(),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFeaturedCarsSection(),
                        const SizedBox(height: 20),
                        _buildRatingsSection(),
                        const SizedBox(height: 20),
                        if (!_isOwnProfile)
                          Row(
                            children: [
                              IconButton(
                                onPressed:
                                    () => ContactLauncher.call(
                                      context,
                                      _companyPhone,
                                    ),
                                icon: const Icon(Icons.phone_outlined),
                                style: IconButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // ⬅️ جديد: واتساب أصبح زر أيقونة صغير مستقل،
                              // والزر الرئيسي "رسالة" أصبح مراسلة حقيقية
                              // داخل التطبيق بدل فتح واتساب خارجي.
                              IconButton(
                                onPressed:
                                    () => ContactLauncher.whatsapp(
                                      context,
                                      _companyPhone,
                                      message:
                                          'مرحباً، أتواصل معكم من تطبيق Syria Motor.',
                                    ),
                                icon: const Icon(Icons.chat_bubble_outline),
                                style: IconButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ChatThreadScreen(
                                              partnerId: _companyId,
                                              partnerName: _companyName,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.message_outlined),
                                  label: const Text('رسالة'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isActingOnFollow ? null : _toggleFollow,
                                  icon: Icon(
                                    (_isFollowing ?? false)
                                        ? Icons.person_remove_alt_1
                                        : Icons.person_add_alt_1,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _isActingOnFollow
                                        ? '...'
                                        : (_isFollowing ?? false)
                                        ? 'إلغاء المتابعة'
                                        : 'متابعة الشركة',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        (_isFollowing ?? false)
                                            ? Colors.black45
                                            : AppColors.primary,
                                    elevation: (_isFollowing ?? false) ? 0 : 2,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
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

  Widget _buildStatsRow() => CompanyStatsRow(
    carsFuture: _companyCarsFuture,
    ratingsFuture: _ratingsFuture,
    followersCount: widget.company['followers_count'],
  );

  Widget _statDivider() => const CompanyStatDivider();

  Widget _statItem(IconData icon, String value, String label) =>
      CompanyStatItem(icon: icon, value: value, label: label);

  Widget _buildFeaturedCarsSection() =>
      FeaturedCarsSection(carsFuture: _companyCarsFuture);

  Widget _buildRatingsSection() => CompanyRatingsSection(
    ratingsFuture: _ratingsFuture,
    onRate: _showRateDialog,
  );

  // عنوان قسم بشارة صغيرة ملوّنة قبل النص بدل نص عادٍ فقط، لمظهر أكثر
  // احترافية ومطابقة لنمط بطاقات باقي الشاشة.
  Widget _sectionTitle(IconData icon, String title) =>
      SectionTitleBadge(icon: icon, title: title);

  Widget _buildRatingItem(Rating r) => CompanyRatingItem(rating: r);

  Future<void> _showRateDialog() async {
    if (_companyId == 0) return;

    // ⬅️ جديد: التقييم أصبح مربوطاً بشكل صارم بمعاملة فعلية مكتملة —
    // نجلب أولاً المعاملات المكتملة معي التي لم أقيّمها بعد، ونعرض فقط
    // ما يخص هذه الشركة تحديداً.
    List<Map<String, dynamic>> ratable;
    try {
      final all = await _ratingService.getRatableTransactions();
      ratable =
          all
              .where((t) => (t['other_user_id'] as num?)?.toInt() == _companyId)
              .toList();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر التحقق من إمكانية التقييم',
        debugMessage: e,
      );
      return;
    }

    if (!mounted) return;

    if (ratable.isEmpty) {
      AppSnackbar.showError(
        context,
        title: 'لا يمكن التقييم الآن',
        subtitle:
            'التقييم متاح فقط بعد إتمام صفقة بيع أو مزاد أو حجز تأجير حقيقي معهم.',
      );
      return;
    }

    Map<String, dynamic>? selectedTransaction = ratable.first;
    if (ratable.length > 1) {
      selectedTransaction = await showDialog<Map<String, dynamic>>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('اختر الصفقة التي تريد تقييمها'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ratable.length,
                  itemBuilder: (context, index) {
                    final t = ratable[index];
                    return ListTile(
                      title: Text(t['title']?.toString() ?? ''),
                      onTap: () => Navigator.pop(dialogContext, t),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
      );
      if (selectedTransaction == null || !mounted) return;
    }

    final Map<String, dynamic> chosenTransaction = selectedTransaction;
    final transactionType = chosenTransaction['type'] as String;
    final transactionId = (chosenTransaction['transaction_id'] as num).toInt();

    int selectedStars = 5;
    final commentController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('قيّم: ${selectedTransaction!['title'] ?? ''}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return IconButton(
                        onPressed:
                            () =>
                                setDialogState(() => selectedStars = starIndex),
                        icon: Icon(
                          starIndex <= selectedStars
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'اكتب تعليقك (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'إرسال',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await _ratingService.addRating(
        userId: _companyId,
        rating: selectedStars,
        comment:
            commentController.text.trim().isEmpty
                ? null
                : commentController.text.trim(),
        type: transactionType,
        transactionId: transactionId,
      );
      _refreshRatings();
      AppSnackbar.showSuccess(context, title: 'تم إرسال تقييمك بنجاح');
    } on ApiException catch (e) {
      AppSnackbar.showError(
        context,
        title: 'تعذّر إرسال التقييم',
        subtitle: e.message,
      );
    } catch (e) {
      AppSnackbar.showError(
        context,
        title: 'تعذّر إرسال التقييم',
        debugMessage: e,
      );
    }
  }
}
