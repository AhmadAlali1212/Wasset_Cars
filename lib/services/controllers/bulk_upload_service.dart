import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/company/bulk_upload_data.dart';

/// خدمة "الرفع الجماعي عبر Excel" — تطابق قسم "13 - الرفع الجماعي Excel"
/// في نسخة Postman المحدّثة. هذا القسم يوفر آلية رفع جماعي حقيقية عبر
/// ملف Excel (وليست مجرد تكرار شاشة إضافة سيارة يدوياً كما في الحل
/// المؤقت السابق CompanyBulkUploadScreen): تنزيل نموذج، معاينة الملف قبل
/// الإرسال، رفعه ومعالجته، ثم متابعة سجل الدفعات المرفوعة (وحالتها لدى
/// الأدمن: pending/approved/rejected — راجع أيضاً قسم
/// "14 - Admin - السيارات / bulk-batches").
class BulkUploadService {
  final BulkUploadData _data = BulkUploadData();

  // رابط تنزيل نموذج Excel الجاهز (يُفتح عادة عبر url_launcher في متصفح
  // خارجي أو تطبيق عرض ملفات، وليس عبر Dio مباشرة).
  String get templateDownloadUrl => _data.templateDownloadUrl;

  // معاينة ملف Excel قبل رفعه فعلياً — يعيد السيرفر عادة عدد الصفوف
  // الصالحة/الخاطئة وأخطاء التحقق لكل صف حتى يصححها المستخدم قبل الإرسال.
  Future<Map<String, dynamic>> previewExcel(File excelFile) async {
    final response = await _data.previewExcel(excelFile);
    _handleResponseErrors(response, 'معاينة ملف الرفع الجماعي');
    return _normalizeResponse(response.data);
  }

  // رفع ومعالجة ملف Excel فعلياً. الإحداثيات الافتراضية تُستخدم للصفوف
  // التي لم تحدد موقعاً خاصاً بها داخل الملف نفسه.
  Future<Map<String, dynamic>> uploadExcel({
    required File excelFile,
    required double defaultLatitude,
    required double defaultLongitude,
  }) async {
    final response = await _data.uploadExcel(
      excelFile: excelFile,
      defaultLatitude: defaultLatitude,
      defaultLongitude: defaultLongitude,
    );
    _handleResponseErrors(response, 'رفع ملف السيارات الجماعي');
    return _normalizeResponse(response.data);
  }

  // سجل كل دفعات الرفع الجماعي السابقة (حالتها وعدد السيارات في كل دفعة)
  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _data.getHistory();
    _handleResponseErrors(response, 'جلب سجل الرفع الجماعي');
    return _normalizeList(response.data);
  }

  List<Map<String, dynamic>> _normalizeList(dynamic data) {
    final list = _extractList(data);
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'batches', 'history', 'items', 'results']) {
        final value = data[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return [];
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
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
