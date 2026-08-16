import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/contact_launcher.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_map_screen.dart';
import 'package:mators_car/screens/company/company_public_profile_screen.dart';
import 'package:mators_car/services/ads_service.dart';
import 'package:mators_car/widgets/seller_rating_badge.dart';
import 'package:mators_car/widgets/section_header.dart';

class AdDetailScreen extends StatefulWidget {
  final Ad ad;
  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  final AdsService _adsService = AdsService();
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  late Ad _ad;

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
    _refreshAdDetails();
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تجهيز رابط الإعلان للمشاركة'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
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
                Stack(
                  children: [
                    SizedBox(
                      height: 260,
                      child: PageView.builder(
                        itemCount: _ad.car.images.length,
                        onPageChanged:
                            (index) =>
                                setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          final imageUrl = _ad.car.images[index];
                          return imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                memCacheWidth: 900,
                                placeholder:
                                    (context, url) => Container(
                                      height: 260,
                                      color: Colors.grey.shade200,
                                    ),
                                errorWidget:
                                    (context, url, error) => Image.asset(
                                      'assets/image/intro.jpg',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                              )
                              : Image.asset(
                                'assets/image/intro.jpg',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((0.5 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${_ad.car.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      _buildFourGridSpecs(),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
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
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ad.contactName.isNotEmpty
                                        ? _ad.contactName
                                        : 'مستخدم Syria Motor',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SellerRatingBadge(userId: _ad.userId),
                                ],
                              ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  () => ContactLauncher.whatsapp(
                                    context,
                                    _ad.contactPhone,
                                    message:
                                        'مرحباً، أنا مهتم بإعلان ${_ad.car.make} ${_ad.car.model} ${_ad.car.year} على تطبيق Syria Motor.',
                                  ),
                              icon: Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.primary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withAlpha(
                                  (0.08 * 255).round(),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed:
                                  () => ContactLauncher.call(
                                    context,
                                    _ad.contactPhone,
                                  ),
                              icon: Icon(
                                Icons.phone_outlined,
                                color: AppColors.primary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withAlpha(
                                  (0.08 * 255).round(),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
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
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => ContactLauncher.call(
                            context,
                            _ad.contactPhone,
                          ),
                      icon: const Icon(
                        Icons.phone_in_talk,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text(
                        'اتصل بالبائع',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handlePurchase,
                      icon: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF1F7A3C),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text(
                        'شراء الآن',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildFourGridSpecs() {
    final specs = [
      {
        'title': 'نوع الوقود',
        'val': _ad.car.fuelType ?? 'غير محدد',
        'icon': Icons.local_gas_station_outlined,
      },
      {
        'title': 'ناقل الحركة',
        'val': _ad.car.transmission ?? 'غير محدد',
        'icon': Icons.settings_input_component_outlined,
      },
      {
        'title': 'السنة',
        'val': _ad.car.year.toString(),
        'icon': Icons.calendar_today_outlined,
      },
      {
        'title': 'العداد',
        'val':
            _ad.car.mileage != null
                ? '${_ad.car.mileage} كم'
                : 'غير محدد',
        'icon': Icons.speed_outlined,
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                specs[index]['icon'] as IconData,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                specs[index]['val'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                specs[index]['title'] as String,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        );
      },
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
