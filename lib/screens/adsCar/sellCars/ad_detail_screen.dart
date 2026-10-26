import 'package:flutter/material.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/contact_launcher.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_map_screen.dart';
import 'package:mators_car/screens/company/company_public_profile_screen.dart';
import 'package:mators_car/screens/messages/chat_thread_screen.dart';
import 'package:mators_car/services/controllers/ads_service.dart';
import 'package:mators_car/services/controllers/favorite_service.dart';
import 'package:mators_car/widgets/section_header.dart';
import 'package:mators_car/widgets/sellCars/ad_detail_widgets.dart';

class AdDetailScreen extends StatefulWidget {
  final Ad ad;
  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  final AdsService _adsService = AdsService();
  final FavoriteService _favoriteService = FavoriteService();
  bool _isFavorite = false;
  bool _isFavoriteBusy = false;
  int _currentImageIndex = 0;
  late Ad _ad;

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
    _refreshAdDetails();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFav = await _favoriteService.isFavorite(_ad.carId);
      if (!mounted) return;
      setState(() => _isFavorite = isFav);
    } catch (_) {
      // تجاهل بصمت: طلب ثانوي، لا يستحق كسر الشاشة
    }
  }

  // ⬅️ استبدال الحل الشكلي المحلي (setState فقط) باستدعاء حقيقي لـ
  // /favorites، بنفس نمط شاشة تفاصيل إعلان التأجير.
  Future<void> _toggleFavorite() async {
    if (_isFavoriteBusy) return;
    setState(() => _isFavoriteBusy = true);
    final wasFavorite = _isFavorite;
    try {
      if (wasFavorite) {
        await _favoriteService.removeFavorite(_ad.carId);
      } else {
        await _favoriteService.addFavorite(_ad.carId);
      }
      if (!mounted) return;
      setState(() => _isFavorite = !wasFavorite);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر تحديث المفضلة',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isFavoriteBusy = false);
    }
  }

  // إعادة جلب أحدث بيانات الإعلان من الخادم عبر GET /ads/{id}
  // (تُبقي بيانات القائمة كعرض فوري، ثم تُحدَّث بأحدث نسخة عند توفرها)
  Future<void> _refreshAdDetails() async {
    try {
      final fresh = await _adsService.getAdDetails(_ad.id);
      if (!mounted || fresh.isEmpty) return;
      final freshAd = Ad.fromJson(fresh);
      // احتياط: إن لم تتضمن استجابة التفاصيل كائن السيارة المتداخل لأي
      // سبب، لا نستبدل بيانات السيارة الجيدة القادمة من شاشة القائمة.
      setState(() {
        _ad = freshAd.car.id != 0 ? freshAd : freshAd.withCar(_ad.car);
      });
    } catch (_) {
      // في حال فشل التحديث نكتفي بعرض البيانات المتوفرة مسبقاً من القائمة
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'تفاصيل الإعلان',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              AppSnackbar.showSuccess(
                context,
                title: 'تم تجهيز رابط الإعلان للمشاركة',
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: _isFavoriteBusy ? null : _toggleFavorite,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معرض الصور الفاخر مع الترقيم التفاعلي الذكي بالأسفل
                AdImageGallery(
                  images: _ad.car.images,
                  currentIndex: _currentImageIndex,
                  onPageChanged:
                      (index) => setState(() => _currentImageIndex = index),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم وموقع السيارة العلوي
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_ad.car.make} ${_ad.car.model} ${_ad.car.year}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdMapScreen(ad: _ad),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _ad.car.location,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'منذ ساعتين',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_ad.price} ل.س',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // شبكة المواصفات الأربعة الكتلية (أيقونات دقيقة وتسمية بالأسفل)
                      AdFourGridSpecs(ad: _ad),
                      const SizedBox(height: 24),

                      const SectionHeader(title: 'الوصف'),
                      const SizedBox(height: 8),
                      Text(
                        _ad.car.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // كارت معلومات البائع التفاعلي والكامل تماماً كما في الرسمة
                      const SectionHeader(title: 'معلومات البائع'),
                      const SizedBox(height: 12),
                      AdSellerContactCard(
                        ad: _ad,
                        onTapSeller: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CompanyPublicProfileScreen(
                                    company: {
                                      'id': _ad.userId,
                                      'name': _ad.contactName,
                                      'phone': _ad.contactPhone,
                                    },
                                  ),
                            ),
                          );
                        },
                        onTapMessage: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatThreadScreen(
                                    partnerId: _ad.userId,
                                    partnerName:
                                        _ad.contactName.isNotEmpty
                                            ? _ad.contactName
                                            : 'مستخدم Syria Motor',
                                  ),
                            ),
                          );
                        },
                        onTapWhatsapp:
                            () => ContactLauncher.whatsapp(
                              context,
                              _ad.contactPhone,
                              message:
                                  'مرحباً، أنا مهتم بإعلان ${_ad.car.make} ${_ad.car.model} ${_ad.car.year} على تطبيق Syria Motor.',
                            ),
                        onTapCall:
                            () =>
                                ContactLauncher.call(context, _ad.contactPhone),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // زر الاتصال المباشر العريض السفلي المدمج
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AdDetailsBottomActionBar(
              onCall: () => ContactLauncher.call(context, _ad.contactPhone),
              onBuyNow: _handlePurchase,
            ),
          ),
        ],
      ),
    );
  }

  // لا يوجد API لإتمام عملية شراء فعلية داخل التطبيق، فالنموذج التجاري هنا
  // قائم على التواصل المباشر مع البائع. لذلك "شراء الآن" يفتح محادثة واتساب
  // برسالة جاهزة تعبّر عن نية الشراء، بدل شاشة "نجاح" وهمية غير مرتبطة
  // بأي عملية حقيقية.
  void _handlePurchase() {
    ContactLauncher.whatsapp(
      context,
      _ad.contactPhone,
      message:
          'مرحباً، أرغب بشراء ${_ad.car.make} ${_ad.car.model} ${_ad.car.year} '
          'المعروضة بسعر ${_ad.price} ل.س على تطبيق Syria Motor.',
    );
  }
}
