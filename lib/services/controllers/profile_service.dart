import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/profile_data.dart';

/// خدمة "الملف الشخصي" — تطابق قسم "21 - الملف الشخصي" في نسخة Postman
/// المحدّثة. هذا القسم لم يكن مغطى سابقاً في التطبيق (لا PUT /profile ولا
/// رفع/حذف صورة البروفايل، ولا معرض صور المستخدم).
class ProfileService {
  final ProfileData _data = ProfileData();

  // تحديث بيانات البروفايل الأساسية (الاسم/رقم الهاتف حالياً حسب Postman،
  // مع السماح بإرسال أي حقول إضافية مستقبلاً عبر extraFields).
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phoneNumber,
    Map<String, dynamic>? extraFields,
  }) async {
    final response = await _data.updateProfile(
      name: name,
      phoneNumber: phoneNumber,
      extraFields: extraFields,
    );
    _handleResponseErrors(response, 'تحديث الملف الشخصي');
    return _normalizeResponse(response.data);
  }

  // رفع/استبدال صورة البروفايل (multipart: avatar)
  Future<Map<String, dynamic>> uploadAvatar(File avatarFile) async {
    final response = await _data.uploadAvatar(avatarFile);
    _handleResponseErrors(response, 'رفع صورة البروفايل');
    return _normalizeResponse(response.data);
  }

  Future<void> deleteAvatar() async {
    final response = await _data.deleteAvatar();
    _handleResponseErrors(response, 'حذف صورة البروفايل');
  }

  // إضافة صورة أو أكثر لمعرض المستخدم (multipart: images[])
  Future<Map<String, dynamic>> addGalleryImages(List<File> images) async {
    final response = await _data.addGalleryImages(images);
    _handleResponseErrors(response, 'إضافة صور المعرض');
    return _normalizeResponse(response.data);
  }

  // حذف صورة محددة من المعرض عبر رابطها الكامل (كما يعيده السيرفر)
  Future<void> deleteGalleryImage(String imageUrl) async {
    final response = await _data.deleteGalleryImage(imageUrl);
    _handleResponseErrors(response, 'حذف صورة من المعرض');
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map && data['user'] is Map) {
      return Map<String, dynamic>.from(data['user'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    final message = _extractValidationMessage(response.data);
    throw Exception('$operation فشل: $message');
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
          if (values.isNotEmpty) lines.add('$key: $values');
        } else if (value is String && value.trim().isNotEmpty) {
          lines.add('$key: ${value.trim()}');
        }
      });
    } else if (errors is String && errors.trim().isNotEmpty) {
      lines.add(errors.trim());
    }
    if (lines.isNotEmpty) return lines.join('\n');
    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'حدث خطأ غير معروف';
  }
}
