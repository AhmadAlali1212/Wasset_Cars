import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/models/car_model.dart';
import 'package:mators_car/services/ads_service.dart';
import 'package:mators_car/services/auth_serivces.dart';
import 'package:mators_car/services/promotion_service.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_detail_screen.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/app_home_style_header.dart';

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
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final myUserId = int.tryParse(
        '${authService.currentUser?['id'] ?? ''}',
      );

      final results = await Future.wait([
        _adsService.getAllAds(status: 'active'),
        _promotionService.getPromotions(),
      ]);

      // ملاحظة: نجلب فقط إعلانات البيع لتغذية أقسام الشاشة الرئيسية
      // (سيارات التطبيق / المضاف حديثاً / جديدة / مستعملة / عروض ترويجية)
      // — سيارات التأجير تظهر حصراً بصفحة التأجير الخاصة بها ولا تُخلط
      // هنا. كما نستثني سياراتي الخاصة (نفس معرّف المستخدم الحالي) من
      // كل هذه الأقسام.
      final saleAds =
          (results[0] as List<Map<String, dynamic>>)
              .map((json) => Ad.fromJson(json))
              .where((ad) => myUserId == null || ad.userId != myUserId)
              .toList();
      final promotions = results[1] as List<Map<String, dynamic>>;

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

      if (!mounted) return;
      setState(() {
        _allCars = cars;
        _recentCars = recentCars.take(10).toList();
        _promotions = promotions;
        _promotedOwnerIds = promotedOwnerIds;
        _promotedCars = promotedCars;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

  Widget _buildDetailChip(IconData icon, String label) {
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
  Widget _buildGridCarCard(Car car) {
    final price = _priceForCar(car);
    final isFavorite = _favoriteCarIds.contains(car.id);
    final specs = [
      if ((car.fuelType ?? '').isNotEmpty) car.fuelType!,
      if ((car.transmission ?? '').isNotEmpty) car.transmission!,
    ].join(' • ');
    final conditionLabel = car.condition == 'new' ? 'جديدة' : 'مستعملة';

    return GestureDetector(
      onTap: () => _openCarDetails(car),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child:
                        car.images.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: car.images[0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              // بطاقة الشبكة بعرض ~180px منطقي فقط، فتحميل
                              // الصورة الأصلية كاملة (قد تصل لعدة ميجابايت)
                              // مبالغ فيه ومكلف جداً بالوقت/الذاكرة.
                              memCacheWidth: 360,
                              placeholder:
                                  (context, url) =>
                                      Container(color: Colors.grey.shade200),
                              errorWidget:
                                  (context, url, error) => Image.asset(
                                    'assets/image/intro.jpg',
                                    fit: BoxFit.cover,
                                  ),
                            )
                            : Image.asset(
                              'assets/image/intro.jpg',
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isFavorite) {
                          _favoriteCarIds.remove(car.id);
                        } else {
                          _favoriteCarIds.add(car.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFavorite ? Colors.red : Colors.black54,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      conditionLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.make} ${car.model} ${car.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (specs.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      specs,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    price > 0 ? _formatPrice(price) : 'السعر عند التواصل',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.more_horiz, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          car.userName.isNotEmpty
                              ? '${car.userName} • ${car.location}'
                              : car.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // واجهة "عرض الكل" لقائمة السيارات — بتصميم شبكي (عمودين) مع بحث وفرز
    if (_viewAllCars != null) {
      final cars = _viewAllFilteredCars;
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            _viewAllTitle ?? 'عرض الكل',
            style: const TextStyle(color: Colors.black, fontSize: 17),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeViewAll,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'تصفية',
              onPressed: () => _showViewAllSortSheet(context),
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                          searchHint: 'ابحث عن سيارة أو موديل...',
                        ),
                        const SizedBox(height: 24),

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
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  // نتائج بحث حقيقية بالشاشة الرئيسية — تُستبدل الأقسام العادية بها فور
  // كتابة أي نص بصندوق البحث، وتُفلتر حسب الماركة/الموديل/سنة الصنع.
  Widget _buildHomeSearchResults() {
    final query = _homeSearchQuery.trim().toLowerCase();
    final results =
        _allCars.where((car) {
          final haystack =
              '${car.make} ${car.model} ${car.year}'.toLowerCase();
          return haystack.contains(query);
        }).toList();

    if (results.isEmpty) {
      return _buildEmptyHint('لا توجد نتائج مطابقة لـ "$_homeSearchQuery"');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final car = results[index];
        return GestureDetector(
          onTap: () => _openCarDetails(car),
          child: _buildCarCard(car),
        );
      },
    );
  }

  Widget _buildEmptyHint(String message) {
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

  Widget _buildSectionHeader(String title, {required VoidCallback onViewAll}) {
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

  Widget _buildCarCard(Car car) {
    final hasPromotion = _promotedOwnerIds.contains(car.userId);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child:
                    car.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: car.images[0],
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // بطاقة الكاروسيل الرئيسية بعرض الشاشة تقريباً؛
                          // نحدّد حجم فك ترميز واقعي بدل الصورة الأصلية.
                          memCacheWidth: 800,
                          placeholder:
                              (context, url) => Container(
                                height: 170,
                                color: Colors.grey.shade200,
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/image/intro.jpg',
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/image/intro.jpg',
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
              ),
              if (hasPromotion)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'عليه عرض',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${car.make} ${car.model} ${car.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        car.location.isEmpty ? 'غير محدد' : car.location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (car.condition.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      car.condition,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCarsRow() => _buildCarsRow(_recentCars);

  Widget _buildPromotedCarsRow() => _buildCarsRow(_promotedCars);

  Widget _buildCarsRow(List<Car> cars) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cars.length,
        itemBuilder: (context, index) {
          final car = cars[index];
          return GestureDetector(
            onTap: () => _openCarDetails(car),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child:
                        car.images.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: car.images[0],
                              height: 95,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              // بطاقة صف أفقي صغيرة (140px عرضاً)؛ حجم فك
                              // ترميز صغير يكفي تماماً ويوفر الكثير.
                              memCacheWidth: 280,
                              placeholder:
                                  (context, url) => Container(
                                    height: 95,
                                    color: Colors.grey.shade200,
                                  ),
                              errorWidget:
                                  (context, url, error) => Image.asset(
                                    'assets/image/intro.jpg',
                                    height: 95,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                            )
                            : Image.asset(
                              'assets/image/intro.jpg',
                              height: 95,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${car.make} ${car.model}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          car.year > 0 ? car.year.toString() : '',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionsRow() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _promotions.length,
        itemBuilder:
            (context, index) => _buildPromotionCard(_promotions[index]),
      ),
    );
  }

  Widget _buildPromotionCard(
    Map<String, dynamic> promo, {
    bool fullWidth = false,
  }) {
    final title = (promo['title'] ?? 'عرض ترويجي').toString();
    final description = (promo['description'] ?? '').toString();
    final type = (promo['type'] ?? '').toString();
    final value = promo['value']?.toString() ?? '';
    final endDate = (promo['end_date'] ?? '').toString();

    final valueLabel =
        value.isEmpty
            ? ''
            : type == 'discount'
            ? 'خصم $value%'
            : value;

    return Container(
      width: fullWidth ? double.infinity : 220,
      margin: EdgeInsets.only(left: fullWidth ? 0 : 12, bottom: fullWidth ? 12 : 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1976D2)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (valueLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    valueLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F4C81),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (endDate.isNotEmpty)
                Text(
                  'حتى $endDate',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int count, int currentIndex) {
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
