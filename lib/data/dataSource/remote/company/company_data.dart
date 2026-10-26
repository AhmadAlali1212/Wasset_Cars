import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ CompanyService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في CompanyService (services/controllers).
class CompanyData {
  final Dio _dio = DioClient.instance.dio;

  // GET /my-cars
  Future<Response> getMyCars() async {
    return _dio.get('/my-cars', options: await _authOptions());
  }

  // GET /my-cars/$carId
  Future<Response> getMyCarDetails(int carId) async {
    return _dio.get(
      '/my-cars/$carId',
      options: await _authOptions(),
    );
  }

  // GET /cars
  Future<Response> getPublicCars() async {
    return _dio.get('/cars', options: await _authOptions());
  }

  // GET /other-users-cars
  Future<Response> getOtherUsersCars() async {
    return _dio.get(
      '/other-users-cars',
      options: await _authOptions(),
    );
  }

  // GET /cars/$carId
  Future<Response> getPublicCarDetails(int carId) async {
    return _dio.get(
      '/cars/$carId',
      options: await _authOptions(),
    );
  }

  // GET /cars/$carId
  Future<Response> getCarDetails(int carId) async {
    return _dio.get(
      '/cars/$carId',
      options: await _authOptions(),
    );
  }

  // POST /cars/$carId | PUT /cars/$carId
  Future<Response> updateCar({
    required int carId,
    required Map<String, dynamic> fields,
    List<File>? newImageFiles,
  }) async {
    Response response;

    if (newImageFiles != null && newImageFiles.isNotEmpty) {
      final formData = FormData.fromMap({...fields, '_method': 'PUT'});
      for (final file in newImageFiles) {
        formData.files.add(
          MapEntry(
            'images[]',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }
      response = await _dio.post(
        '/cars/$carId',
        data: formData,
        options: await _authOptions(),
      );
    } else {
      response = await _dio.put(
        '/cars/$carId',
        data: fields,
        options: await _authOptions(),
      );
    }
    return response;
  }

  // GET /ads?status=active
  Future<Response> getAllCars() async {
    return _dio.get(
      '/ads?status=active',
      options: await _authOptions(),
    );
  }

  // GET /wallet
  Future<Response> getWallet() async {
    return _dio.get('/wallet', options: await _authOptions());
  }

  // POST /wallet/stripe/create-intent
  Future<Response> createStripeTopupIntent({
    required double amountUsd,
    String? requestId,
  }) async {
    return _dio.post(
      '/wallet/stripe/create-intent',
      data: {
        'amount_usd': amountUsd,
        if (requestId != null && requestId.trim().isNotEmpty)
          'request_id': requestId.trim(),
      },
      options: await _authOptions(),
    );
  }

  // GET /wallet/stripe/topups/$requestId
  Future<Response> getStripeTopupStatus(String requestId) async {
    return _dio.get(
      '/wallet/stripe/topups/$requestId',
      options: await _authOptions(),
    );
  }

  // POST /wallet/withdraw
  Future<Response> withdrawWallet({
    required double amount,
    required String withdrawalMethod,
    required String destination,
  }) async {
    return _dio.post(
      '/wallet/withdraw',
      data: {
        'amount': amount,
        'withdrawal_method': withdrawalMethod,
        'destination': destination,
      },
      options: await _authOptions(),
    );
  }

  // POST /cars
  Future<Response> addCar({
    required Map<String, dynamic> fields,
    List<File>? imageFiles,
    // ⬅️ جديد: فيديوهات اختيارية عند إنشاء السيارة (بحد أقصى 2)
    List<File>? videoFiles,
  }) async {
    final formData = FormData.fromMap(fields);

    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (final file in imageFiles) {
        const fieldName = 'images[]';
        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }
    }

    if (videoFiles != null && videoFiles.isNotEmpty) {
      for (final file in videoFiles) {
        const fieldName = 'videos[]';
        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }
    }

    final response = await _dio.post(
      '/cars',
      data: formData,
      options: await _authOptions(),
    );
    return response;
  }

  // POST /cars/$carId/videos
  Future<Response> addCarVideos({
    required int carId,
    required List<File> videoFiles,
  }) async {
    final formData = FormData();
    for (final file in videoFiles) {
      formData.files.add(
        MapEntry(
          'videos[]',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }

    final response = await _dio.post(
      '/cars/$carId/videos',
      data: formData,
      options: await _authOptions(),
    );
    return response;
  }

  // DELETE /cars/$carId/videos
  Future<Response> removeCarVideo({
    required int carId,
    required String videoUrl,
  }) async {
    return _dio.delete(
      '/cars/$carId/videos',
      data: {'video_url': videoUrl},
      options: await _authOptions(),
    );
  }

  // POST /cars/$carId/request-inspection
  Future<Response> requestInspection(int carId) async {
    return _dio.post(
      '/cars/$carId/request-inspection',
      options: await _authOptions(),
    );
  }

  // DELETE /cars/$carId
  Future<Response> deleteCar(int carId) async {
    return _dio.delete(
      '/cars/$carId',
      options: await _authOptions(),
    );
  }

  // ✅ تعديل أهم خطوة: إضافة Accept Header لتحديد استجابة JSON
  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}
