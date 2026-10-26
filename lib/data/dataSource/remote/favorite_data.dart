import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ FavoriteService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في FavoriteService (services/controllers).
class FavoriteData {
  final Dio _dio = DioClient.instance.dio;

  // POST /favorites
  Future<Response> addFavorite(int carId) async {
    return _dio.post(
      '/favorites',
      data: {'car_id': carId},
      options: await _authOptions(),
    );
  }

  // DELETE /favorites/$carId
  Future<Response> removeFavorite(int carId) async {
    return _dio.delete(
      '/favorites/$carId',
      options: await _authOptions(),
    );
  }

  // GET /favorites/$carId/status
  Future<Response> isFavorite(int carId) async {
    return _dio.get(
      '/favorites/$carId/status',
      options: await _authOptions(),
    );
  }

  // GET /favorites
  Future<Response> getMyFavorites() async {
    return _dio.get(
      '/favorites',
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
