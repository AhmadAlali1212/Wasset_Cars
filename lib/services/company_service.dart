import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../ulits/constans.dart';

class CompanyService {
  final Dio _dio;

  CompanyService() : _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  Future<List<Map<String, dynamic>>> getCompanyCars() async {
    final response = await _dio.get('/cars', options: await _authOptions());
    _handleResponseErrors(response, 'جلب سيارات المعرض');

    if (response.data is List) {
      return List<Map<String, dynamic>>.from(
        (response.data as List).map((item) => Map<String, dynamic>.from(item)),
      );
    }

    if (response.data is Map && response.data['data'] is List) {
      return List<Map<String, dynamic>>.from(
        (response.data['data'] as List).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    }

    return [];
  }

  Future<Map<String, dynamic>> getWallet() async {
    final response = await _dio.get('/wallet', options: await _authOptions());
    _handleResponseErrors(response, 'جلب المحفظة');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> addCar({
    required Map<String, dynamic> fields,
    List<File>? imageFiles,
  }) async {
    final formData = FormData.fromMap(fields);

    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (final file in imageFiles) {
        final fieldName = 'images[]';
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

    _handleResponseErrors(response, 'إضافة سيارة جديدة');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> requestInspection(int carId) async {
    final response = await _dio.post(
      '/cars/$carId/request-inspection',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'طلب الفحص الفني');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteCar(int carId) async {
    final response = await _dio.delete(
      '/cars/$carId',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'حذف السيارة');
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    final message = _extractValidationMessage(response.data);
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: '$operation فشل: $message',
      error: '$operation فشل: $message',
    );
  }

  String _extractValidationMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is! Map) {
      return 'حدث خطأ غير معروف';
    }

    final map = Map<String, dynamic>.from(data);
    final errors = map['errors'];
    final lines = <String>[];

    if (errors is Map && errors.isNotEmpty) {
      errors.forEach((key, value) {
        if (value is List) {
          final values = value.map((item) => item.toString()).join(', ');
          if (values.isNotEmpty) {
            lines.add('$key: $values');
          }
        } else if (value is String && value.trim().isNotEmpty) {
          lines.add('$key: ${value.trim()}');
        }
      });
    } else if (errors is String && errors.trim().isNotEmpty) {
      lines.add(errors.trim());
    }

    if (lines.isNotEmpty) {
      return lines.join('\n');
    }

    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return 'حدث خطأ غير معروف';
  }
}
