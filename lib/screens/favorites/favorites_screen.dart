import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mators_car/data/models/ad_model.dart';
import 'package:mators_car/screens/adsCar/sellCars/ad_detail_screen.dart';
import 'package:mators_car/screens/adsCar/rental/rentalAd_details_creen.dart';
import 'package:mators_car/services/controllers/favorite_service.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';

/// شاشة "مفضلتي" — النتيجة الحقيقية لأزرار القلب بكل شاشات التطبيق، بعد
/// أن كانت شكلية محلية فقط (تُفقد عند إغلاق التطبيق ولا تُزامَن بأي مكان).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  late Future<List<Map<String, dynamic>>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _favoriteService.getMyFavorites();
  }

  Future<void> _refresh() async {
    setState(() {
      _favoritesFuture = _favoriteService.getMyFavorites();
    });
    await _favoritesFuture;
  }

  Future<void> _removeFavorite(int carId) async {
    try {
      await _favoriteService.removeFavorite(carId);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تمت الإزالة من المفضلة');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, title: 'تعذّر إزالة السيارة', debugMessage: e);
    }
  }

  // كل عنصر مفضلة يحمل السيارة (car)، وقد تتضمن السيارة إعلان بيع (ad)
  // و/أو إعلان تأجير (rentalAd) و/أو مزاد (auction). نبني كائن Ad كامل
  // (بدمج بيانات السيارة داخله) لإعادة استخدام شاشات التفاصيل الموجودة.
  void _openDetails(BuildContext context, Map<String, dynamic> favorite) {
    final car = favorite['car'];
    if (car is! Map) return;
    final carJson = Map<String, dynamic>.from(car);

    final saleAd = carJson['ad'];
    final rentalAd = carJson['rentalAd'] ?? carJson['rental_ad'];

    if (saleAd is Map) {
      final adJson = Map<String, dynamic>.from(saleAd)..['car'] = carJson;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdDetailScreen(ad: Ad.fromJson(adJson))),
      );
      return;
    }

    if (rentalAd is Map) {
      final adJson = Map<String, dynamic>.from(rentalAd)..['car'] = carJson;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RentalAdDetailScreen(ad: Ad.fromJson(adJson))),
      );
      return;
    }

    AppSnackbar.showError(context, title: 'لم يعد هذا الإعلان متاحاً');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('مفضلتي', style: TextStyle(color: Colors.black)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 6);
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text('تعذر جلب المفضلة\n${snapshot.error}',
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              );
            }

            final favorites = snapshot.data ?? [];
            if (favorites.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.favorite_border, size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد سيارات في مفضلتك بعد')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                final car = favorite['car'];
                if (car is! Map) return const SizedBox.shrink();

                final carId = (car['id'] as num?)?.toInt() ?? 0;
                final make = car['make']?.toString() ?? '';
                final model = car['model']?.toString() ?? '';
                final year = car['year']?.toString() ?? '';
                final images = car['images'];
                final imageUrl = images is List && images.isNotEmpty
                    ? images.first.toString()
                    : null;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openDetails(context, favorite),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 144,
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: const Color(0xFFF0F0F0),
                                  child: const Icon(Icons.directions_car, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$make $model $year',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFavorite(carId),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
