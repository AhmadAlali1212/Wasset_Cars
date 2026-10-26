import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/favorite_data.dart';

/// خدمة المفضلة (Favorites) — تستبدل أزرار القلب الشكلية المحلية
/// (SharedPreferences/State فقط) بمزامنة حقيقية مع الخادم.
class FavoriteService {
  final FavoriteData _data = FavoriteData();

  // إضافة سيارة للمفضلة
  Future<void> addFavorite(int carId) async {
    final response = await _data.addFavorite(carId);
    _handleResponseErrors(response, 'إضافة السيارة للمفضلة');
  }

  // إزالة سيارة من المفضلة
  Future<void> removeFavorite(int carId) async {
    final response = await _data.removeFavorite(carId);
    _handleResponseErrors(response, 'إزالة السيارة من المفضلة');
  }

  // التحقق: هل هذه السيارة ضمن مفضلتي؟
  Future<bool> isFavorite(int carId) async {
    final response = await _data.isFavorite(carId);
    _handleResponseErrors(response, 'التحقق من المفضلة');
    final data = response.data;
    if (data is Map && data['is_favorite'] is bool) {
      return data['is_favorite'] as bool;
    }
    return false;
  }

  // جلب كل السيارات المفضّلة لدي
  Future<List<Map<String, dynamic>>> getMyFavorites() async {
    final response = await _data.getMyFavorites();
    _handleResponseErrors(response, 'جلب المفضلة');
    final data = response.data;
    List list = [];
    if (data is Map) {
      final favorites = data['favorites'];
      if (favorites is Map && favorites['data'] is List) {
        list = favorites['data'] as List;
      } else if (favorites is List) {
        list = favorites;
      }
    }
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return;
    }
    final data = response.data;
    String message = 'حدث خطأ غير معروف';
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }
    throw Exception('$operation فشل: $message');
  }
}
