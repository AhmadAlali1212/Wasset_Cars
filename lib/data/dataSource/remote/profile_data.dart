import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ ProfileService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في ProfileService (services/controllers).
class ProfileData {
  final Dio _dio = DioClient.instance.dio;

  // PUT /profile
  Future<Response> updateProfile({
    String? name,
    String? phoneNumber,
    Map<String, dynamic>? extraFields,
  }) async {
    return _dio.put(
      '/profile',
      data: {
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (extraFields != null) ...extraFields,
      },
      options: await _authOptions(),
    );
  }

  // POST /profile/avatar
  Future<Response> uploadAvatar(File avatarFile) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        avatarFile.path,
        filename: avatarFile.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _dio.post(
      '/profile/avatar',
      data: formData,
      options: await _authOptions(),
    );
    return response;
  }

  // DELETE /profile/avatar
  Future<Response> deleteAvatar() async {
    return _dio.delete(
      '/profile/avatar',
      options: await _authOptions(),
    );
  }

  // POST /profile/gallery
  Future<Response> addGalleryImages(List<File> images) async {
    final formData = FormData.fromMap({});
    for (final file in images) {
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
    final response = await _dio.post(
      '/profile/gallery',
      data: formData,
      options: await _authOptions(),
    );
    return response;
  }

  // DELETE /profile/gallery
  Future<Response> deleteGalleryImage(String imageUrl) async {
    return _dio.delete(
      '/profile/gallery',
      data: {'image_url': imageUrl},
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
