import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ RentalAdService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في RentalAdService (services/controllers).
class RentalAdData {
  final Dio _dio = DioClient.instance.dio;

  // POST /rental-ads
  Future<Response> createRentalAd({
    required int carId,
    required double dailyPrice,
    double? monthlyPrice,
    String? rentalConditions,
  }) async {
    return _dio.post(
      '/rental-ads',
      data: {
        'car_id': carId,
        'daily_price': dailyPrice,
        if (monthlyPrice != null) 'monthly_price': monthlyPrice,
        if (rentalConditions != null && rentalConditions.trim().isNotEmpty)
          'rental_conditions': rentalConditions.trim(),
      },
      options: await _authOptions(),
    );
  }

  // GET /rental-ads
  Future<Response> getAllRentalAds({
    double? minDailyPrice,
    double? maxDailyPrice,
    String? location,
    double? userLat,
    double? userLng,
    double? radius,
    int? perPage,
    int? page,
  }) async {
    return _dio.get(
      '/rental-ads',
      queryParameters: {
        if (minDailyPrice != null) 'min_daily_price': minDailyPrice,
        if (maxDailyPrice != null) 'max_daily_price': maxDailyPrice,
        if (location != null && location.isNotEmpty) 'location': location,
        if (userLat != null) 'user_lat': userLat,
        if (userLng != null) 'user_lng': userLng,
        if (radius != null) 'radius': radius,
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      },
      options: await _authOptions(),
    );
  }

  // GET /rental-ads/my
  Future<Response> getMyRentalAds({String? status}) async {
    return _dio.get(
      '/rental-ads/my',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: await _authOptions(),
    );
  }

  // GET /rental-ads/my/$rentalAdId
  Future<Response> getMyRentalAdDetails(int rentalAdId) async {
    return _dio.get(
      '/rental-ads/my/$rentalAdId',
      options: await _authOptions(),
    );
  }

  // GET /rental-ads/$rentalAdId
  Future<Response> getRentalAdDetails(int rentalAdId) async {
    return _dio.get(
      '/rental-ads/$rentalAdId',
      options: await _authOptions(),
    );
  }

  // PUT /rental-ads/$rentalAdId
  Future<Response> updateRentalAd({
    required int rentalAdId,
    double? dailyPrice,
    double? monthlyPrice,
    String? rentalConditions,
  }) async {
    return _dio.put(
      '/rental-ads/$rentalAdId',
      data: {
        if (dailyPrice != null) 'daily_price': dailyPrice,
        if (monthlyPrice != null) 'monthly_price': monthlyPrice,
        if (rentalConditions != null)
          'rental_conditions': rentalConditions.trim(),
      },
      options: await _authOptions(),
    );
  }

  // POST /rental-ads/$rentalAdId/publish
  Future<Response> publishRentalAd(int rentalAdId) async {
    return _dio.post(
      '/rental-ads/$rentalAdId/publish',
      options: await _authOptions(),
    );
  }

  // DELETE /rental-ads/$rentalAdId
  Future<Response> deleteRentalAd(int rentalAdId) async {
    return _dio.delete(
      '/rental-ads/$rentalAdId',
      options: await _authOptions(),
    );
  }

  // GET /rental-ads/$rentalAdId/availability
  Future<Response> getUnavailableRanges(
    int rentalAdId,
  ) async {
    return _dio.get(
      '/rental-ads/$rentalAdId/availability',
      options: await _authOptions(),
    );
  }

  // POST /rental-ads/$rentalAdId/unavailable-dates
  Future<Response> addUnavailableDates({
    required int rentalAdId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.post(
      '/rental-ads/$rentalAdId/unavailable-dates',
      data: {
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      options: await _authOptions(),
    );
    return response;
  }

  // DELETE /rental-ads/$rentalAdId/unavailable-dates/$unavailabilityId
  Future<Response> removeUnavailableDates({
    required int rentalAdId,
    required int unavailabilityId,
  }) async {
    return _dio.delete(
      '/rental-ads/$rentalAdId/unavailable-dates/$unavailabilityId',
      options: await _authOptions(),
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
