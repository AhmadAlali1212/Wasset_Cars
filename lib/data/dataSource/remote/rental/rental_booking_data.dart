import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ RentalBookingService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في RentalBookingService (services/controllers).
class RentalBookingData {
  final Dio _dio = DioClient.instance.dio;

  // POST /rental-bookings
  Future<Response> createBooking({
    required int rentalAdId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final response = await _dio.post(
      '/rental-bookings',
      data: {
        'rental_ad_id': rentalAdId,
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
      },
      options: await _authOptions(),
    );
    return response;
  }

  // GET /rental-bookings/my
  Future<Response> getMyBookings() async {
    return _dio.get(
      '/rental-bookings/my',
      options: await _authOptions(),
    );
  }

  // DELETE /rental-bookings/$bookingId
  Future<Response> cancelBooking(int bookingId) async {
    return _dio.delete(
      '/rental-bookings/$bookingId',
      options: await _authOptions(),
    );
  }

  // GET /rental-bookings/incoming
  Future<Response> getIncomingBookings({
    String? status,
  }) async {
    return _dio.get(
      '/rental-bookings/incoming',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: await _authOptions(),
    );
  }

  // POST /rental-bookings/$bookingId/approve
  Future<Response> approveBooking(int bookingId) async {
    return _dio.post(
      '/rental-bookings/$bookingId/approve',
      options: await _authOptions(),
    );
  }

  // POST /rental-bookings/$bookingId/reject
  Future<Response> rejectBooking(int bookingId, {String? reason}) async {
    return _dio.post(
      '/rental-bookings/$bookingId/reject',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      options: await _authOptions(),
    );
  }

  // POST /rental-bookings/$bookingId/mark-delivered
  Future<Response> markDelivered(int bookingId) async {
    return _dio.post(
      '/rental-bookings/$bookingId/mark-delivered',
      options: await _authOptions(),
    );
  }

  // POST /rental-bookings/$bookingId/mark-returned
  Future<Response> markReturned(int bookingId) async {
    return _dio.post(
      '/rental-bookings/$bookingId/mark-returned',
      options: await _authOptions(),
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}
