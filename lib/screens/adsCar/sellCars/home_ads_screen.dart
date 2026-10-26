import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/data/models/car_model.dart';
import 'package:mators_car/services/controllers/ads_service.dart';
import 'package:mators_car/services/controllers/auth_service.dart';
import 'package:mators_car/services/controllers/promotion_service.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_detail_screen.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/services/local_cache.dart';
import 'package:mators_car/services/controllers/favorite_service.dart';
import 'package:mators_car/widgets/sellCars/home_common_widgets.dart';
import 'package:mators_car/widgets/sellCars/car_cards.dart';
import 'package:mators_car/widgets/sellCars/promotion_widgets.dart';
import 'package:mators_car/widgets/sellCars/home_search_results.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PromotionService _promotionService = PromotionService();
  final AdsService _adsService = AdsService();

  // بيانات حقيقية من الـ API:
  // ملاحظة مهمة: لا يوجد نقطة "قائمة كل السيارات" عامة لعامة المستخدمين في
  // الـ API الفعلي (تأكدنا من هذا مباشرة من Postman: مجلدات إدارة السيارات
  // للفرد/المعرض فيها فقط إضافة/تعديل/حذف/فحص، وقوائم العرض بالكامل مخصصة
  // للأدمن فقط). سيارة تصبح "عامة" ومرئية لبقية المستخدمين فقط عبر إعلان
  // بيع (Ads) أو إعلان تأجير (Rental Ads) منشور عليها — لذلك نجمع السيارات
  // من هذين المصدرين المؤكد عملهما بدل الاعتماد على /cars.
  List<Car> _allCars = [];
  List<Car> _recentCars = [];
  List<Map<String, dynamic>> _promotions = [];
  // نحتفظ بالإعلان الكامل (بيع/تأجير) لكل سيارة حسب معرفها، لأن قائمة
  // السيارات المعروضة بهذه الشاشة تُختصر لكائنات Car فقط، وبدون هذا لا
  // نقدر نفتح شاشة التفاصيل الحقيقية (تحتاج السعر ومعرف الإعلان وغيرها).
  final Map<int, Ad> _saleAdByCarId = {};
  final Map<int, Ad> _rentalAdByCarId = {};
  // معرفات كل مستخدم (شركة/فرد) عنده عرض ترويجي نشط حالياً، لعرض شارة
  // "عليه عرض" على كل سيارات نفس المستخدم بدل سيارة واحدة فقط.
  Set<int> _promotedOwnerIds = {};
  List<Car> _promotedCars = [];
  bool _isLoading = true;
  String? _errorMessage;
  // ⬅️ جديد: تخزين محلي/Offline — عند فشل الاتصال، نعرض آخر بيانات محفوظة
  // بدل شاشة فاضية بالكامل، مع شريط تنبيه واضح أنها بيانات قديمة.
  bool _isShowingCachedData = false;
  DateTime? _cachedAt;
  static const String _homeCacheKey = 'home_sale_ads';
  static const String _homePromotionsCacheKey = 'home_promotions';
  final FavoriteService _favoriteService = FavoriteService();

  final PageController _appCarsPageController = PageController();
  int _currentAppCarIndex = 0;

  // واجهة "عرض الكل" العامة (تُستخدم لأقسام السيارات والعروض معاً)
  String? _viewAllTitle;
  List<Car>? _viewAllCars;
  List<Map<String, dynamic>>? _viewAllPromotions;
  // بحث/فرز محليان داخل شاشة "عرض الكل" الخاصة بالسيارات
  final TextEditingController _viewAllSearchController = TextEditingController();
  String _viewAllSearchQuery = '';
  String _viewAllSort = 'newest'; // newest | price_desc | price_asc
  // مفضّلة محلية فقط (لا يوجد endpoint مفضّلة بالـ API حتى الآن)، بنفس
  // أسلوب زر القلب بشاشة تفاصيل الإعلان (تبديل شكلي دون حفظ بالسيرفر)
  final Set<int> _favoriteCarIds = {};

  // عدد الإشعارات غير المقروءة أصبح يُدار داخل AppHomeStyleHeader نفسها
  // (رأس موحّد لكل الصفحات)، فلا داعي لتكراره هنا.

  // بحث حقيقي بالشاشة الرئيسية — كان صندوق البحث شكلياً بدون أي وظيفة
  final TextEditingController _homeSearchController = TextEditingController();
  String _homeSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _loadFavorites();
    _homeScrollController.addListener(_onHomeScroll);
  }

  // ⬅️ استبدال Set<int> محلي بحت (يُفقد عند إغلاق التطبيق) بمزامنة حقيقية
  // مع /favorites، بنفس منطق شاشة تفاصيل الإعلان.
  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteService.getMyFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteCarIds
          ..clear()
          ..addAll(
            favorites
                .map((f) {
                  final car = f['car'];
                  if (car is Map) return int.tryParse('${car['id']}');
                  return int.tryParse('${f['car_id']}');
                })
                .whereType<int>(),
          );
      });
    } catch (_) {
      // فشل صامت: القلوب ستبقى فارغة حتى أول تفاعل ناجح، لا داعي لكسر الشاشة
    }
  }

  Future<void> _toggleFavorite(Car car) async {
    final wasFavorite = _favoriteCarIds.contains(car.id);
    setState(() {
      if (wasFavorite) {
        _favoriteCarIds.remove(car.id);
      } else {
        _favoriteCarIds.add(car.id);
      }
    });
    try {
      if (wasFavorite) {
        await _favoriteService.removeFavorite(car.id);
      } else {
        await _favoriteService.addFavorite(car.id);
      }
    } catch (e) {
      if (!mounted) return;
      // فشل الطلب الفعلي: نتراجع عن التحديث الفوري (optimistic) ونبلغ المستخدم
      setState(() {
        if (wasFavorite) {
          _favoriteCarIds.add(car.id);
        } else {
          _favoriteCarIds.remove(car.id);
        }
      });
      AppSnackbar.showError(context, title: 'تعذّر تحديث المفضلة', debugMessage: e);
    }
  }

  // ⬅️ جديد: صفحة حالية + علم "توجد صفحات أخرى" لتحميل تدريجي حقيقي
  // (Infinite Scroll)، بدل الحل السابق (جلب كل الصفحات دفعة واحدة عند
  // فتح الشاشة، وهو أبطأ بأول تحميل وأثقل على الشبكة بلا داعٍ).
  static const int _homePageSize = 20;
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  final ScrollController _homeScrollController = ScrollController();

  // ⬅️ جديد: إعادة حساب "الأحدث" و"المروَّجة" من _allCars الحالية —
  // تُستدعى بعد كل تحميل صفحة (أولى أو إضافية) بدل تكرار نفس المنطق
  void _recomputeDerivedLists() {
    final recentCars = List<Car>.from(_allCars)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _recentCars = recentCars.take(10).toList();
    _promotedCars =
        _allCars.where((car) => _promotedOwnerIds.contains(car.userId)).toList();
  }

  // ⬅️ جديد: تحميل الصفحة التالية عند الاقتراب من نهاية التمرير — هذا هو
  // الـ Infinite Scroll الحقيقي الذي يستبدل حل "اجلب كل الصفحات دفعة
  // واحدة" السابق. يضيف السيارات الجديدة فوق نفس _allCars تدريجياً، وكل
  // الأقسام المشتقة منها (الجديدة/المستعملة/المروَّجة/نتائج البحث) تكبر
  // تلقائياً معها بدون أي منطق إضافي.
  Future<void> _loadMoreHomeData() async {
    if (_isLoadingMore || !_hasMorePages || _isLoading) return;

    setState(() => _isLoadingMore = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final myUserId = int.tryParse('${authService.currentUser?['id'] ?? ''}');
      final nextPage = _currentPage + 1;

      final saleAdsRaw = await _adsService.getAllAds(
        status: 'active',
        page: nextPage,
        perPage: _homePageSize,
      );

      final saleAds = saleAdsRaw
          .map((json) => Ad.fromJson(json))
          .where((ad) => myUserId == null || ad.userId != myUserId)
          .toList();

      for (final ad in saleAds) {
        if (ad.car.id != 0) {
          _saleAdByCarId[ad.car.id] = ad;
        }
      }
      final newCars = saleAds
          .map((ad) => ad.car)
          .where((car) => car.id != 0)
          .toList();
      final existingIds = _allCars.map((c) => c.id).toSet();

      if (!mounted) return;
      setState(() {
        _allCars = [
          ..._allCars,
          ...newCars.where((c) => !existingIds.contains(c.id)),
        ];
        _recomputeDerivedLists();
        _currentPage = nextPage;
        _hasMorePages = saleAdsRaw.length >= _homePageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      // فشل تحميل صفحة إضافية ليس خطأ يستحق مقاطعة المستخدم — نتوقف
      // بصمت عن محاولة التحميل التلقائي، وتبقى السيارات المحمَّلة سابقاً ظاهرة
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    final position = _homeScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMoreHomeData();
    }
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final myUserId = int.tryParse(
        '${authService.currentUser?['id'] ?? ''}',
      );

      final results = await Future.wait([
        // ⬅️ جديد: نجلب أول صفحة فقط الآن (بدل كل الصفحات دفعة واحدة) —
        // بقية الصفحات تُجلب تدريجياً أثناء النزول بالتمرير (_loadMoreHomeData)
        _adsService.getAllAds(status: 'active', page: 1, perPage: _homePageSize),
        _promotionService.getPromotions(),
      ]);

      final saleAdsRaw = results[0] as List<Map<String, dynamic>>;
      final promotions = results[1] as List<Map<String, dynamic>>;

      // احفظ آخر نتيجة ناجحة محلياً لعرضها لاحقاً عند انقطاع الاتصال
      LocalCache.save(_homeCacheKey, saleAdsRaw);
      LocalCache.save(_homePromotionsCacheKey, promotions);

      // ملاحظة: نجلب فقط إعلانات البيع لتغذية أقسام الشاشة الرئيسية
      // (سيارات التطبيق / المضاف حديثاً / جديدة / مستعملة / عروض ترويجية)
      // — سيارات التأجير تظهر حصراً بصفحة التأجير الخاصة بها ولا تُخلط
      // هنا. كما نستثني سياراتي الخاصة (نفس معرّف المستخدم الحالي) من
      // كل هذه الأقسام.
      final saleAds =
          saleAdsRaw
              .map((json) => Ad.fromJson(json))
              .where((ad) => myUserId == null || ad.userId != myUserId)
              .toList();

      _saleAdByCarId.clear();
      _rentalAdByCarId.clear();
      final carsById = <int, Car>{};
      for (final ad in saleAds) {
        if (ad.car.id != 0) {
          carsById[ad.car.id] = ad.car;
          _saleAdByCarId[ad.car.id] = ad;
        }
      }
      final cars = carsById.values.toList();

      if (!mounted) return;
      setState(() {
        _allCars = cars;
        _promotions = promotions;
        _promotedOwnerIds = PromotionService.extractOwnerIds(promotions);
        _recomputeDerivedLists();
        _isLoading = false;
        _isShowingCachedData = false;
        // صفحة أولى أقل من حجمها الكامل تعني هذا كل شيء فعلياً (لا صفحات أخرى)
        _hasMorePages = saleAdsRaw.length >= _homePageSize;
      });
    } catch (e) {
      // ⬅️ جديد: عند فشل الجلب (غالباً انقطاع اتصال)، نحاول عرض آخر بيانات
      // محفوظة محلياً بدل شاشة فاضية بالكامل، مع تنبيه واضح أنها قديمة.
      final cachedSaleAdsRaw = await LocalCache.read(_homeCacheKey);
      final cachedPromotionsRaw = await LocalCache.read(_homePromotionsCacheKey);
      if (!mounted) return;

      if (cachedSaleAdsRaw is List) {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          final myUserId = int.tryParse('${authService.currentUser?['id'] ?? ''}');

          final saleAds = cachedSaleAdsRaw
              .map((json) => Ad.fromJson(Map<String, dynamic>.from(json)))
              .where((ad) => myUserId == null || ad.userId != myUserId)
              .toList();
          final promotions = cachedPromotionsRaw is List
              ? List<Map<String, dynamic>>.from(
                  cachedPromotionsRaw.map((e) => Map<String, dynamic>.from(e)))
              : <Map<String, dynamic>>[];

          final carsById = <int, Car>{};
          _saleAdByCarId.clear();
          _rentalAdByCarId.clear();
          for (final ad in saleAds) {
            if (ad.car.id != 0) {
              carsById[ad.car.id] = ad.car;
              _saleAdByCarId[ad.car.id] = ad;
            }
          }
          final cars = carsById.values.toList();
          final recentCars = List<Car>.from(cars)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final promotedOwnerIds = PromotionService.extractOwnerIds(promotions);
          final promotedCars =
              cars.where((car) => promotedOwnerIds.contains(car.userId)).toList();
          final cachedAt = await LocalCache.lastSavedAt(_homeCacheKey);

          if (!mounted) return;
          setState(() {
            _allCars = cars;
            _recentCars = recentCars.take(10).toList();
            _promotions = promotions;
            _promotedOwnerIds = promotedOwnerIds;
            _promotedCars = promotedCars;
            _isLoading = false;
            _isShowingCachedData = true;
            _cachedAt = cachedAt;
            _errorMessage = null;
            // البيانات المحفوظة محلياً لقطة واحدة ثابتة — لا صفحات إضافية
            // متاحة للتحميل التدريجي أثناء انقطاع الاتصال
            _hasMorePages = false;
          });
          return;
        } catch (_) {
          // إن فشل تحليل الكاش المحلي نفسه، نكمل لعرض رسالة الخطأ العادية
        }
      }

      setState(() {
        _errorMessage = 'تعذر جلب بيانات الرئيسية: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _appCarsPageController.dispose();
    _viewAllSearchController.dispose();
    _homeSearchController.dispose();
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    super.dispose();
  }

  // السعر الفعلي للسيارة يأتي من إعلان البيع المرتبط بها (لا يوجد على
  // كائن Car نفسه)، لذلك نبحث عنه ضمن الخريطة المبنية أثناء التحميل.
  double _priceForCar(Car car) {
    final ad = _saleAdByCarId[car.id];
    if (ad == null) return 0;
    return double.tryParse(ad.price.replaceAll(',', '')) ?? 0;
  }

  String _formatPrice(double price) {
    final priceStr = price.toStringAsFixed(0);
    var formatted = '';
    var counter = 0;
    for (var i = priceStr.length - 1; i >= 0; i--) {
      counter++;
      formatted = priceStr[i] + formatted;
      if (counter % 3 == 0 && i != 0) formatted = ',$formatted';
    }
    return '$formatted ل.س';
  }

  // تصنيف سيارات "سيارات التطبيق" حسب حالتها الفعلية القادمة من السيرفر
  // (car.condition تكون 'new' أو 'used' بالضبط حسب تحقق الباك-إند)
  List<Car> get _newCars => _allCars.where((c) => c.condition == 'new').toList();
  List<Car> get _usedCars => _allCars.where((c) => c.condition == 'used').toList();

  // ⬅️ جديد: فلاتر بحث متقدمة حقيقية (كان البحث نصياً بسيطاً فقط بالسابق)
  double? _filterMinPrice;
  double? _filterMaxPrice;
  int? _filterYearFrom;
  int? _filterYearTo;
  String? _filterCondition; // 'new' | 'used' | null (الكل)

  bool get _hasActiveAdvancedFilters =>
      _filterMinPrice != null ||
      _filterMaxPrice != null ||
      _filterYearFrom != null ||
      _filterYearTo != null ||
      _filterCondition != null;

  List<Car> get _viewAllFilteredCars {
    final source = _viewAllCars ?? const <Car>[];
    final query = _viewAllSearchQuery.trim().toLowerCase();
    var list =
        query.isEmpty
            ? List<Car>.from(source)
            : source
                .where(
                  (car) =>
                      '${car.make} ${car.model} ${car.year}'
                          .toLowerCase()
                          .contains(query),
                )
                .toList();

    if (_filterMinPrice != null) {
      list = list.where((car) => _priceForCar(car) >= _filterMinPrice!).toList();
    }
    if (_filterMaxPrice != null) {
      list = list.where((car) => _priceForCar(car) <= _filterMaxPrice!).toList();
    }
    if (_filterYearFrom != null) {
      list = list.where((car) => car.year >= _filterYearFrom!).toList();
    }
    if (_filterYearTo != null) {
      list = list.where((car) => car.year <= _filterYearTo!).toList();
    }
    if (_filterCondition != null) {
      list = list.where((car) => car.condition == _filterCondition).toList();
    }

    switch (_viewAllSort) {
      case 'price_desc':
        list.sort((a, b) => _priceForCar(b).compareTo(_priceForCar(a)));
        break;
      case 'price_asc':
        list.sort((a, b) => _priceForCar(a).compareTo(_priceForCar(b)));
        break;
      default: // newest
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  // يفتح شاشة التفاصيل الحقيقية المطابقة (بيع أو تأجير) لهذه السيارة.
  // إذا كان لها الاثنان معاً، نفتح إعلان البيع افتراضياً (الأكثر شيوعاً
  // بهذه الشاشة الرئيسية)، وإلا نعرض المعاينة المصغّرة كخيار احتياطي فقط.
  void _openCarDetails(Car car) {
    final saleAd = _saleAdByCarId[car.id];
    if (saleAd != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdDetailScreen(ad: saleAd)),
      );
      return;
    }
    final rentalAd = _rentalAdByCarId[car.id];
    if (rentalAd != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RentalAdDetailScreen(ad: rentalAd)),
      );
      return;
    }
    _showCarDetails(car);
  }

  void _showCarDetails(Car car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (car.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        child: PageView(
                          children:
                              car.images
                                  .map(
                                    (url) => CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      // العرض الفعلي هنا حتى ~600px منطقي؛
                                      // نحدّد حجم فك الترميز بما يقارب ذلك
                                      // بدل تحميل الصورة الأصلية كاملة
                                      // (قد تكون عدة ميجابايت من كاميرا
                                      // هاتف)، وهذا يقلّل استهلاك الذاكرة
                                      // والوقت بشكل كبير.
                                      memCacheWidth: 700,
                                      placeholder:
                                          (context, url) => Container(
                                            color: Colors.grey.shade200,
                                          ),
                                      errorWidget:
                                          (context, url, error) => Image.asset(
                                                'assets/image/intro.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    '${car.make} ${car.model} ${car.year}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailChip(Icons.info_outline, car.condition),
                      _buildDetailChip(
                        Icons.location_on_outlined,
                        car.location,
                      ),
                      if (car.userName.isNotEmpty)
                        _buildDetailChip(Icons.person_outline, car.userName),
                    ],
                  ),
                  if (car.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'الوصف',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      car.description,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailChip(IconData icon, String label) => DetailChip(icon, label);

  void _showAllCars(String title, List<Car> cars) {
    setState(() {
      _viewAllTitle = title;
      _viewAllCars = cars;
      _viewAllPromotions = null;
      _viewAllSearchQuery = '';
      _viewAllSort = 'newest';
      _viewAllSearchController.clear();
    });
  }

  void _showAllPromotions(String title, List<Map<String, dynamic>> promos) {
    setState(() {
      _viewAllTitle = title;
      _viewAllPromotions = promos;
      _viewAllCars = null;
    });
  }

  void _closeViewAll() {
    setState(() {
      _viewAllTitle = null;
      _viewAllCars = null;
      _viewAllPromotions = null;
    });
  }

  String _sortLabel(String sort) {
    switch (sort) {
      case 'price_desc':
        return 'السعر: الأعلى أولاً';
      case 'price_asc':
        return 'السعر: الأقل أولاً';
      default:
        return 'الأحدث أولاً';
    }
  }

  // ⬅️ جديد: شيت فلاتر بحث متقدمة حقيقية — نطاق سعر، نطاق سنة، والحالة
  // (جديدة/مستعملة)، بدل الاكتفاء ببحث نصي وترتيب فقط.
  // ⬅️ جديد: نص مختصر يلخّص الفلاتر النشطة حالياً
  String _activeFiltersSummary() {
    final parts = <String>[];
    if (_filterMinPrice != null || _filterMaxPrice != null) {
      final min = _filterMinPrice?.toStringAsFixed(0) ?? '0';
      final max = _filterMaxPrice?.toStringAsFixed(0) ?? '∞';
      parts.add('السعر: $min - $max');
    }
    if (_filterYearFrom != null || _filterYearTo != null) {
      final from = _filterYearFrom?.toString() ?? '';
      final to = _filterYearTo?.toString() ?? '';
      parts.add('السنة: $from - $to');
    }
    if (_filterCondition != null) {
      parts.add(_filterCondition == 'new' ? 'جديدة' : 'مستعملة');
    }
    return parts.join(' | ');
  }

  void _showAdvancedFiltersSheet(BuildContext context) {
    final minPriceController = TextEditingController(
      text: _filterMinPrice?.toStringAsFixed(0) ?? '',
    );
    final maxPriceController = TextEditingController(
      text: _filterMaxPrice?.toStringAsFixed(0) ?? '',
    );
    final yearFromController = TextEditingController(
      text: _filterYearFrom?.toString() ?? '',
    );
    final yearToController = TextEditingController(
      text: _filterYearTo?.toString() ?? '',
    );
    String? condition = _filterCondition;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('فلاتر البحث', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              minPriceController.clear();
                              maxPriceController.clear();
                              yearFromController.clear();
                              yearToController.clear();
                              condition = null;
                            });
                          },
                          child: const Text('مسح الكل'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('نطاق السعر (دولار)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'من',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'إلى',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('سنة الصنع', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: yearFromController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'من',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: yearToController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'إلى',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('الحالة', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('الكل'),
                          selected: condition == null,
                          onSelected: (_) => setSheetState(() => condition = null),
                        ),
                        ChoiceChip(
                          label: const Text('جديدة'),
                          selected: condition == 'new',
                          onSelected: (_) => setSheetState(() => condition = 'new'),
                        ),
                        ChoiceChip(
                          label: const Text('مستعملة'),
                          selected: condition == 'used',
                          onSelected: (_) => setSheetState(() => condition = 'used'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterMinPrice = double.tryParse(minPriceController.text.trim());
                            _filterMaxPrice = double.tryParse(maxPriceController.text.trim());
                            _filterYearFrom = int.tryParse(yearFromController.text.trim());
                            _filterYearTo = int.tryParse(yearToController.text.trim());
                            _filterCondition = condition;
                          });
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('تطبيق الفلاتر', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showViewAllSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget option(String value, String label) {
          final selected = _viewAllSort == value;
          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.primary : Colors.black87,
              ),
            ),
            trailing:
                selected ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () {
              setState(() => _viewAllSort = value);
              Navigator.pop(sheetContext);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ترتيب النتائج',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              option('newest', 'الأحدث أولاً'),
              option('price_desc', 'السعر: الأعلى أولاً'),
              option('price_asc', 'السعر: الأقل أولاً'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // بطاقة السيارة بتصميم الشبكة (عمودين) لشاشة "عرض الكل": صورة + قلب
  // مفضّلة + شارة الحالة، ثم الاسم والمواصفات والسعر واسم البائع/الموقع.
  Widget _buildGridCarCard(Car car) => GridCarCard(
        car: car,
        price: _priceForCar(car),
        isFavorite: _favoriteCarIds.contains(car.id),
        onTap: () => _openCarDetails(car),
        onToggleFavorite: () => _toggleFavorite(car),
        formatPrice: _formatPrice,
      );

  @override
  Widget build(BuildContext context) {
    // واجهة "عرض الكل" لقائمة السيارات — بتصميم شبكي (عمودين) مع بحث وفرز
    if (_viewAllCars != null) {
      final cars = _viewAllFilteredCars;
      return Scaffold(
        backgroundColor: context.adaptiveScaffoldBg,
        appBar: AppBar(
          backgroundColor: context.adaptiveCardBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.adaptiveTextPrimary),
          title: Text(
            _viewAllTitle ?? 'عرض الكل',
            style: TextStyle(color: context.adaptiveTextPrimary, fontSize: 17),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeViewAll,
          ),
          actions: [
            IconButton(
              icon: Badge(
                isLabelVisible: _hasActiveAdvancedFilters,
                child: const Icon(Icons.tune),
              ),
              tooltip: 'فلاتر متقدمة',
              onPressed: () => _showAdvancedFiltersSheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _viewAllSearchController,
                        textAlign: TextAlign.right,
                        onChanged:
                            (value) =>
                                setState(() => _viewAllSearchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن سيارة...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _showViewAllSortSheet(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.filter_list, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cars.length} سيارة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showViewAllSortSheet(context),
                    child: Row(
                      children: [
                        Text(
                          _sortLabel(_viewAllSort),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const Icon(Icons.expand_more, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ⬅️ جديد: ملخص الفلاتر النشطة + زر مسحها السريع
            if (_hasActiveAdvancedFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _activeFiltersSummary(),
                        style: TextStyle(color: AppColors.primary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterMinPrice = null;
                          _filterMaxPrice = null;
                          _filterYearFrom = null;
                          _filterYearTo = null;
                          _filterCondition = null;
                        });
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('مسح', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  cars.isEmpty
                      ? const Center(child: Text('لا توجد سيارات لعرضها'))
                      : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.68,
                            ),
                        itemCount: cars.length,
                        itemBuilder:
                            (context, index) => _buildGridCarCard(cars[index]),
                      ),
            ),
          ],
        ),
      );
    }

    // واجهة "عرض الكل" لقائمة العروض الترويجية
    if (_viewAllPromotions != null) {
      final promos = _viewAllPromotions!;
      return Scaffold(
        appBar: AppBar(
          title: Text(_viewAllTitle ?? 'كل العروض الترويجية'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeViewAll,
          ),
        ),
        body:
            promos.isEmpty
                ? const Center(child: Text('لا توجد عروض ترويجية حالياً'))
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: promos.length,
                  itemBuilder:
                      (context, index) =>
                          _buildPromotionCard(promos[index], fullWidth: true),
                ),
      );
    }

    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          child:
              _isLoading
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: const [SkeletonCarGrid(itemCount: 6)],
                  )
                  : _errorMessage != null
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  )
                  : SingleChildScrollView(
                    controller: _homeScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        AppHomeStyleHeader(
                          title: 'سوريا موتورز',
                          searchController: _homeSearchController,
                          onSearchChanged:
                              (v) => setState(() => _homeSearchQuery = v),
                          searchHint: context.tr('search_hint'),
                        ),
                        const SizedBox(height: 24),

                        if (_isShowingCachedData) _buildOfflineBanner(),

                        if (_homeSearchQuery.isEmpty) ...[
                        // القسم 1: كل سيارات التطبيق
                        _buildSectionHeader(
                          'سيارات التطبيق',
                          onViewAll:
                              () => _showAllCars('سيارات التطبيق', _allCars),
                        ),
                        const SizedBox(height: 12),
                        if (_allCars.isEmpty)
                          _buildEmptyHint('لا توجد سيارات مضافة على التطبيق بعد')
                        else ...[
                          SizedBox(
                            height: 300,
                            child: PageView.builder(
                              controller: _appCarsPageController,
                              itemCount: _allCars.length,
                              onPageChanged:
                                  (index) => setState(
                                    () => _currentAppCarIndex = index,
                                  ),
                              itemBuilder: (context, index) {
                                final car = _allCars[index];
                                return GestureDetector(
                                  onTap: () => _openCarDetails(car),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: _buildCarCard(car),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPageIndicator(
                            _allCars.length,
                            _currentAppCarIndex,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // القسم 2: السيارات المضافة حديثاً
                        _buildSectionHeader(
                          'المضاف حديثاً',
                          onViewAll:
                              () => _showAllCars(
                                'المضاف حديثاً',
                                _recentCars,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _recentCars.isEmpty
                            ? _buildEmptyHint('لا توجد إضافات حديثة بعد')
                            : _buildRecentCarsRow(),

                        const SizedBox(height: 24),

                        // القسم 3: سيارات جديدة (condition == 'new')
                        _buildSectionHeader(
                          'سيارات جديدة',
                          onViewAll: () => _showAllCars('سيارات جديدة', _newCars),
                        ),
                        const SizedBox(height: 12),
                        _newCars.isEmpty
                            ? _buildEmptyHint('لا توجد سيارات جديدة حالياً')
                            : _buildCarsRow(_newCars),

                        const SizedBox(height: 24),

                        // القسم 4: سيارات مستعملة (condition == 'used')
                        _buildSectionHeader(
                          'سيارات مستعملة',
                          onViewAll: () => _showAllCars('سيارات مستعملة', _usedCars),
                        ),
                        const SizedBox(height: 12),
                        _usedCars.isEmpty
                            ? _buildEmptyHint('لا توجد سيارات مستعملة حالياً')
                            : _buildCarsRow(_usedCars),

                        const SizedBox(height: 24),

                        // القسم 5: سيارات العروض الترويجية — نعرض سيارات
                        // الشركات التي لديها عرض ترويجي نشط حالياً (وليس
                        // بطاقة العرض نفسها)، لأن العرض الترويجي بالـ API
                        // حملة عامة تابعة للشركة وليس مرتبطاً بسيارة محددة.
                        _buildSectionHeader(
                          'سيارات العروض الترويجية',
                          onViewAll:
                              () => _showAllCars(
                                'سيارات العروض الترويجية',
                                _promotedCars,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _promotedCars.isEmpty
                            ? _buildEmptyHint('لا توجد سيارات عليها عروض ترويجية حالياً')
                            : _buildPromotedCarsRow(),
                        ] else
                          _buildHomeSearchResults(),
                        // ⬅️ جديد: مؤشر تحميل الصفحة التالية (Infinite Scroll)
                        _buildLoadMoreFooter(),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  // ⬅️ جديد: مؤشر أسفل الشاشة يظهر أثناء تحميل الصفحة التالية تلقائياً،
  // أو رسالة "هذا كل شيء" عند الوصول لآخر صفحة فعلياً
  Widget _buildLoadMoreFooter() => LoadMoreFooter(
        isLoadingMore: _isLoadingMore,
        hasMorePages: _hasMorePages,
        showEndMessage: _allCars.isNotEmpty && _homeSearchQuery.isEmpty,
      );

  // ⬅️ جديد: شريط تنبيه عند عرض بيانات محفوظة محلياً بسبب انقطاع الاتصال
  Widget _buildOfflineBanner() => OfflineBanner(cachedAt: _cachedAt, onRetry: _loadHomeData);

  // كتابة أي نص بصندوق البحث، وتُفلتر حسب الماركة/الموديل/سنة الصنع.
  Widget _buildHomeSearchResults() => HomeSearchResultsGrid(
        allCars: _allCars,
        query: _homeSearchQuery,
        hasPromotion: (car) => _promotedOwnerIds.contains(car.userId),
        onCarTap: (car) => _openCarDetails(car),
      );

  Widget _buildEmptyHint(String message) => EmptyHint(message);

  Widget _buildSectionHeader(String title, {required VoidCallback onViewAll}) =>
      HomeSectionHeader(title: title, onViewAll: onViewAll);

  Widget _buildCarCard(Car car) => HomeCarCard(
        car: car,
        hasPromotion: _promotedOwnerIds.contains(car.userId),
      );

  Widget _buildRecentCarsRow() => _buildCarsRow(_recentCars);

  Widget _buildPromotedCarsRow() => _buildCarsRow(_promotedCars);

  Widget _buildCarsRow(List<Car> cars) => HomeCarsRow(
        cars: cars,
        onCarTap: (car) => _openCarDetails(car),
      );

  Widget _buildPromotionsRow() => PromotionsRow(promotions: _promotions);

  Widget _buildPromotionCard(
    Map<String, dynamic> promo, {
    bool fullWidth = false,
  }) =>
      PromotionCard(promo: promo, fullWidth: fullWidth);

  Widget _buildPageIndicator(int count, int currentIndex) =>
      PageDotsIndicator(count: count, currentIndex: currentIndex);
}
