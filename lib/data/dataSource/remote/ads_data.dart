import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ AdsService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في AdsService (services/controllers).
class AdsData {
  final Dio _dio = DioClient.instance.dio;

  // GET /my-ads
  Future<Response> getMyAds({String? status}) async {
    return _dio.get(
      '/my-ads',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: await _authOptions(),
    );
  }

  // GET /my-ads/$adId
  Future<Response> getMyAdDetails(int adId) async {
    return _dio.get(
      '/my-ads/$adId',
      options: await _authOptions(),
    );
  }

  // GET /ads
  Future<Response> getAllAds({
    String? status,
    double? minPrice,
    double? maxPrice,
    String? make,
    double? userLat,
    double? userLng,
    double? radius,
    int? userId,
    int? perPage,
    int? page,
  }) async {
    return _dio.get(
      '/ads',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (make != null && make.isNotEmpty) 'make': make,
        if (userLat != null) 'user_lat': userLat,
        if (userLng != null) 'user_lng': userLng,
        if (radius != null) 'radius': radius,
        if (userId != null) 'user_id': userId,
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      },
      options: await _authOptions(),
    );
  }

  // GET /ads/$adId
  Future<Response> getAdDetails(int adId) async {
    return _dio.get(
      '/ads/$adId',
      options: await _authOptions(),
    );
  }

  // GET /other-users-ads
  Future<Response> getOtherUsersAds() async {
    return _dio.get(
      '/other-users-ads',
      options: await _authOptions(),
    );
  }

  // POST /ads
  Future<Response> createAd({
    required int carId,
    required double price,
  }) async {
    return _dio.post(
      '/ads',
      data: {'car_id': carId, 'price': price},
      options: await _authOptions(),
    );
  }

  // PUT /ads/bulk-publish
  Future<Response> bulkUpdatePrices(
    List<Map<String, dynamic>> ads,
  ) async {
    return _dio.put(
      '/ads/bulk-publish',
      data: {'ads': ads},
      options: await _authOptions(),
    );
  }

  // PUT /my-ads/$adId
  Future<Response> updateAd({
    required int adId,
    required double price,
  }) async {
    return _dio.put(
      '/my-ads/$adId',
      data: {'price': price},
      options: await _authOptions(),
    );
  }

  // POST /my-ads/$adId/renew
  Future<Response> renewAd(
    int adId, {
    bool stillAvailable = true,
  }) async {
    return _dio.post(
      '/my-ads/$adId/renew',
      data: {'still_available': stillAvailable},
      options: await _authOptions(),
    );
  }

  // POST /my-ads/$adId/publish
  Future<Response> publishAd(int adId) async {
    return _dio.post(
      '/my-ads/$adId/publish',
      options: await _authOptions(),
    );
  }

  // DELETE /my-ads/$adId
  Future<Response> deleteAd(int adId) async {
    return _dio.delete(
      '/my-ads/$adId',
      options: await _authOptions(),
    );
  }

  // POST /my-ads/$adId/mark-sold
  Future<Response> markSold(int adId, {int? buyerId}) async {
    return _dio.post(
      '/my-ads/$adId/mark-sold',
      data: {if (buyerId != null) 'buyer_id': buyerId},
      options: await _authOptions(),
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
