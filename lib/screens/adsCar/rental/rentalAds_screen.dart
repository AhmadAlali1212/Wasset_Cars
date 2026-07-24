import 'package:flutter/material.dart';
import 'package:mators_car/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/mock_data.dart' show MockData;
import 'package:mators_car/widgets/section_header.dart';

class RentalAdsScreen extends StatefulWidget {
  const RentalAdsScreen({super.key});

  @override
  State<RentalAdsScreen> createState() => _RentalAdsScreenState();
}

class _RentalAdsScreenState extends State<RentalAdsScreen> {
  final List<Ad> rentalAds = MockData.rentalAds;

  // متغيرات منطق البحث وعرض الكل
  String _searchQuery = '';
  bool _isSearching = false;
  List<Ad>? _viewAllList;
  String? _viewAllTitle;

  // دالة التنقل للتفاصيل
  void _navigateToDetail(Ad ad, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RentalAdDetailScreen(ad: ad)),
    );
  }

  // دالة تفعيل واجهة "عرض الكل"
  void _showAllAds(String title, List<Ad> ads) {
    setState(() {
      _viewAllTitle = title;
      _viewAllList = ads;
    });
  }

  @override
  Widget build(BuildContext context) {
    // تصفية الإعلانات بناءً على نص البحث (البحث في الماركة أو الموديل)
    final filteredAds =
        rentalAds.where((ad) {
          final fullName = '${ad.car.make} ${ad.car.model}'.toLowerCase();
          return fullName.contains(_searchQuery.toLowerCase());
        }).toList();

    final featuredAds = filteredAds.where((ad) => ad.isFeatured).toList();

    // واجهة "عرض الكل" في حال تم الضغط عليها
    if (_viewAllList != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_viewAllTitle ?? 'إعلانات التأجير'),
          centerTitle: true,
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRentalAdCard(_viewAllList![index], context),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title:
            _isSearching
                ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    autofocus: true,
                    textAlign: TextAlign.right,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن سيارة للتأجير...',
                      border: InputBorder.none,
                    ),
                  ),
                )
                : const Text(
                  'إعلانات تأجير السيارات',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        leading: IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.black,
          ),
          onPressed:
              () => setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              }),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 1. قسم الإعلانات المميزة (يختفي أثناء البحث لتسهيل تجربة المستخدم)
          if (!_isSearching && featuredAds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(
                title: 'إعلانات مميزة',
                onViewAll:
                    () => _showAllAds(
                      'إعلانات مميزة',
                      rentalAds.where((ad) => ad.isFeatured).toList(),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height:
                  290, // زيادة الارتفاع ليتناسب مع أبعاد التصميم الجديد المرفق بالصورة
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: featuredAds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildFeaturedRentalCard(
                      featuredAds[index],
                      context,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. جميع إعلانات التأجير
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(
              title: 'جميع إعلانات التأجير',
              onViewAll: () => _showAllAds('جميع إعلانات التأجير', rentalAds),
            ),
          ),
          const SizedBox(height: 12),

          filteredAds.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('لا توجد نتائج تطابق بحثك'),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredAds.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRentalAdCard(filteredAds[index], context),
                  );
                },
              ),
        ],
      ),
    );
  }

  // الكرت المميز الكبير (مطابق للصورة تماماً بمقاييس الكود الخاص بك)
  Widget _buildFeaturedRentalCard(Ad ad, BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(ad, context),
      child: Container(
        width: 320,
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
                  child: _buildImageWidget(
                    ad.car.images.isNotEmpty ? ad.car.images[0] : null,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'مميز',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 12,
                  left: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '1 / ${ad.car.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ل.س ${ad.dailyPrice} / يوم',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ad.car.location,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'أو ل.س ${ad.monthlyPrice} / شهر',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          ad.status == 'pending'
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ad.status == 'pending' ? 'قيد المراجعة' : 'متوفر',
                      style: TextStyle(
                        color:
                            ad.status == 'pending'
                                ? AppColors.warning
                                : AppColors.success,
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
      ),
    );
  }

  // الكرت الصغير الأفقي لـ "جميع إعلانات التأجير" (مطابق للصورة)
  Widget _buildRentalAdCard(Ad ad, BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetail(ad, context),
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: _buildImageWidget(
                    ad.car.images.isNotEmpty ? ad.car.images[0] : null,
                    width: 130,
                    height: 115,
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 12,
                    child: Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '1 / ${ad.car.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ad.car.make} ${ad.car.model} ${ad.car.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          ad.car.location,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ل.س ${ad.dailyPrice} / يوم',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'أو ل.س ${ad.monthlyPrice} / شهر',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                ad.status == 'pending'
                                    ? AppColors.warning.withOpacity(0.1)
                                    : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ad.status == 'pending' ? 'قيد المراجعة' : 'متوفر',
                            style: TextStyle(
                              color:
                                  ad.status == 'pending'
                                      ? AppColors.warning
                                      : AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/image/intro.jpg',
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }
    return Image.asset(
      'assets/image/intro.jpg',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
