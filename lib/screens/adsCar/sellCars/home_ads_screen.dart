import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_detail_screen.dart';
import 'package:mators_car/ulits/mock_data.dart' show MockData;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Ad> _featuredAds = MockData.featuredAds;
  final List<Ad> _recommendedAds = MockData.recommendedAds;

  // وحدة التحكم للـ PageView الخاص بالإعلانات المميزة
  final PageController _featuredPageController = PageController();
  int _currentFeaturedIndex = 0;

  // قائمة لعرض السيارات المفروزة عند الضغط على عرض الكل
  List<Ad>? _viewAllList;
  String? _viewAllTitle;

  @override
  void dispose() {
    _featuredPageController.dispose();
    super.dispose();
  }

  void _navigateToAdDetail(Ad ad) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdDetailScreen(ad: ad)),
    );
  }

  // دالة لعرض كافة السيارات بصفحة منفصلة سريعة عند الضغط على "عرض الكل"
  void _showAllAds(String title, List<Ad> ads) {
    setState(() {
      _viewAllTitle = title;
      _viewAllList = ads;
    });
  }

  @override
  Widget build(BuildContext context) {
    // واجهة "عرض الكل" في حال تم الضغط عليها
    if (_viewAllList != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_viewAllTitle ?? 'كل الإعلانات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                () => setState(() {
                  _viewAllList = null;
                  _viewAllTitle = null;
                }),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _viewAllList!.length,
          itemBuilder: (context, index) {
            final ad = _viewAllList![index];
            return GestureDetector(
              onTap: () => _navigateToAdDetail(ad),
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ad.car.images.isNotEmpty
                        ? Image.network(
                          ad.car.images[0],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Image.asset(
                                'assets/image/intro.jpg',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        )
                        : Image.asset(
                          'assets/image/intro.jpg',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                    ListTile(
                      title: Text('${ad.car.make} ${ad.car.model}'),
                      subtitle: Text('${ad.price} ل.س'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                  const Text(
                    'سوريا موتورز',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سيارة أو موديل...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: السيارات المميزة
              _buildSectionHeader(
                'السيارات المميزة',
                onViewAll: () {
                  _showAllAds('السيارات المميزة', _featuredAds);
                },
              ),
              const SizedBox(height: 12),

              // ✅ تفعيل واجهة السحب والتنقل الأفقي بين السيارات المميزة بالكامل
              if (_featuredAds.isNotEmpty) ...[
                SizedBox(
                  height: 340, // ارتفاع متناسق لاحتواء كامل الكرت والـ Button
                  child: PageView.builder(
                    controller: _featuredPageController,
                    itemCount: _featuredAds.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentFeaturedIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final ad = _featuredAds[index];
                      return GestureDetector(
                        onTap: () => _navigateToAdDetail(ad),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildFeaturedCard(ad),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildPageIndicator(_featuredAds.length, _currentFeaturedIndex),
              ],

              const SizedBox(height: 24),

              // Section 2: إعلانات موصى بها
              _buildSectionHeader(
                'إعلانات موصى بها',
                onViewAll: () {
                  _showAllAds('إعلانات موصى بها', _recommendedAds);
                },
              ),
              const SizedBox(height: 12),
              _buildRecommendedAdsGrid(),

              const SizedBox(height: 24),

              // Section 3: المضاف حديثاً
              _buildSectionHeader(
                'المضاف حديثاً',
                onViewAll: () {
                  _showAllAds('المضاف حديثاً', _recommendedAds);
                },
              ),
              const SizedBox(height: 12),
              _buildRecentlyAddedRow(),
            ],
          ),
        ),
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

  Widget _buildFeaturedCard(Ad ad) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    ad.car.images.isNotEmpty
                        ? Image.network(
                          ad.car.images[0],
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Image.asset(
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
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        ad.status == 'pending' ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ad.status == 'pending' ? 'قيد المراجعة' : 'منشور',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ad.car.location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.speed, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '120,000 كم',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      '${ad.price} ل.س',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _navigateToAdDetail(ad),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.arrow_back_ios,
                          size: 11,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'عرض التفاصيل',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildRecommendedAdsGrid() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedAds.length,
        itemBuilder: (context, index) {
          final ad = _recommendedAds[index];
          return GestureDetector(
            onTap: () => _navigateToAdDetail(ad),
            child: Container(
              width: 200,
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
                        ad.car.images.isNotEmpty
                            ? Image.network(
                              ad.car.images[0],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Image.asset(
                                    'assets/image/intro.jpg',
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                            )
                            : Image.asset(
                              'assets/image/intro.jpg',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ad.car.make} ${ad.car.model}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ad.price} ل.س',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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

  Widget _buildRecentlyAddedRow() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedAds.length,
        itemBuilder: (context, index) {
          final ad = _recommendedAds[index];
          return GestureDetector(
            onTap: () => _navigateToAdDetail(ad),
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
                        ad.car.images.isNotEmpty
                            ? Image.network(
                              ad.car.images[0],
                              height: 95,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Image.asset(
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
                          '${ad.car.make} ${ad.car.model}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ad.price} ل.س',
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

  // ✅ تعديل الـ Indicator ليكون ديناميكياً مع عدد السيارات الفعلي والكرت الحالي مفعّل
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
