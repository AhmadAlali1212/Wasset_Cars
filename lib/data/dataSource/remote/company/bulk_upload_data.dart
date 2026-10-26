import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';
import 'package:mators_car/ulits/constant.dart';

/// طلبات الباك الخام لـ BulkUploadService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في BulkUploadService (services/controllers).
class BulkUploadData {
  final Dio _dio = DioClient.instance.dio;

  // رابط تنزيل نموذج Excel الجاهز (يُفتح عادة عبر url_launcher في متصفح
  // خارجي أو تطبيق عرض ملفات، وليس عبر Dio مباشرة).
  String get templateDownloadUrl =>
      '${AppConstants.baseUrl}/bulk-upload/template';

  // POST /bulk-upload/preview
  Future<Response> previewExcel(File excelFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        excelFile.path,
        filename: excelFile.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _dio.post(
      '/bulk-upload/preview',
      data: formData,
      options: await _authOptions(),
    );
    return response;
  }

  // POST /bulk-upload
  Future<Response> uploadExcel({
    required File excelFile,
    required double defaultLatitude,
    required double defaultLongitude,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        excelFile.path,
        filename: excelFile.path.split(Platform.pathSeparator).last,
      ),
      'default_latitude': defaultLatitude.toStringAsFixed(6),
      'default_longitude': defaultLongitude.toStringAsFixed(6),
    });
    final response = await _dio.post(
      '/bulk-upload',
      data: formData,
      options: await _authOptions(),
    );
    return response;
  }

  // GET /bulk-upload/history
  Future<Response> getHistory() async {
    return _dio.get('/bulk-upload/history', options: await _authOptions());
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}
