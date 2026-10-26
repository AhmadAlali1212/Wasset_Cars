import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ AuctionService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في AuctionService (services/controllers).
class AuctionData {
  final Dio _dio = DioClient.instance.dio;

  // GET /auctions
  Future<Response> getAuctions({String? status}) async {
    return _dio.get(
      '/auctions',
      queryParameters: status != null ? {'status': status} : null,
      options: await _authOptions(),
    );
  }

  // GET /my-auctions
  Future<Response> getMyAuctions({
    String? status,
    String? timeStatus,
  }) async {
    return _dio.get(
      '/my-auctions',
      queryParameters: {
        if (status != null) 'status': status,
        if (timeStatus != null) 'time_status': timeStatus,
      },
      options: await _authOptions(),
    );
  }

  // GET /auctions/$auctionId
  Future<Response> getAuctionDetails(int auctionId) async {
    return _dio.get(
      '/auctions/$auctionId',
      options: await _authOptions(),
    );
  }

  // POST /auctions
  Future<Response> createAuction({
    required int carId,
    required double startingPrice,
    required int durationHours,
  }) async {
    return _dio.post(
      '/auctions',
      data: {
        'car_id': carId,
        'starting_price': startingPrice,
        'duration_hours': durationHours,
      },
      options: await _authOptions(),
    );
  }

  // PUT /auctions/$auctionId
  Future<Response> updateAuction({
    required int auctionId,
    required double startingPrice,
    required int durationHours,
  }) async {
    return _dio.put(
      '/auctions/$auctionId',
      data: {'starting_price': startingPrice, 'duration_hours': durationHours},
      options: await _authOptions(),
    );
  }

  // POST /auctions/$auctionId/bid
  Future<Response> placeBid({
    required int auctionId,
    required double amount,
  }) async {
    return _dio.post(
      '/auctions/$auctionId/bid',
      data: {'amount': amount},
      options: await _authOptions(),
    );
  }

  // POST /auctions/close-expired
  Future<Response> closeExpiredAuctions() async {
    return _dio.post(
      '/auctions/close-expired',
      options: await _authOptions(),
    );
  }

  // POST /auctions/$auctionId/accept-final-price
  Future<Response> acceptFinalPrice(int auctionId) async {
    return _dio.post(
      '/auctions/$auctionId/accept-final-price',
      options: await _authOptions(),
    );
  }

  // POST /auctions/$auctionId/reject-final-price
  Future<Response> rejectFinalPrice(int auctionId) async {
    return _dio.post(
      '/auctions/$auctionId/reject-final-price',
      options: await _authOptions(),
    );
  }

  // POST /auctions/$auctionId/complete-sale
  Future<Response> completeSale(int auctionId) async {
    return _dio.post(
      '/auctions/$auctionId/complete-sale',
      options: await _authOptions(),
    );
  }

  // POST /auctions/$auctionId/winner-withdraw
  Future<Response> winnerWithdraw(int auctionId) async {
    return _dio.post(
      '/auctions/$auctionId/winner-withdraw',
      options: await _authOptions(),
    );
  }

  // DELETE /auctions/$auctionId
  Future<Response> deleteAuction(int auctionId) async {
    return _dio.delete(
      '/auctions/$auctionId',
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
