import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// استثناء موحّد لأخطاء الـ API.
// يحمل statusCode الحقيقي القادم من السيرفر (403, 422, 500 ...) مع رسالة
// عربية جاهزة للعرض، بدل تسريب نص DioException الخام للمستخدم.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  // حالة خاصة شائعة: رفض الطلب لأن الاشتراك غير نشط
  bool get isSubscriptionRequired {
    if (statusCode != 403) return false;
    final text = message.toLowerCase();
    return text.contains('اشتراك') ||
        text.contains('subscription') ||
        text.contains('subscribe');
  }

  bool get isForbidden => statusCode == 403;

  // حالة شائعة أخرى: رفض الطلب لعدم كفاية رصيد المحفظة (مزايدة، اشتراك، شحن...)
  bool get isInsufficientBalance {
    final text = message.toLowerCase();
    return text.contains('رصيد') ||
        text.contains('insufficient') ||
        text.contains('balance');
  }

  /// يحوّل الخطأ إلى نص مناسب للعرض، ولا يسمح بتسريب صفحات HTML من الخادم.
  static String userMessage(
    Object? error, {
    String fallback = 'حدث خطأ أثناء تحميل البيانات',
  }) {
    if (error == null) return fallback;

    debugPrint('API error details: $error');

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'تعذر الاتصال بالخادم، يرجى المحاولة مرة أخرى';
        case DioExceptionType.connectionError:
          return 'لا يوجد اتصال بالخادم، تحقق من الإنترنت وحاول مرة أخرى';
        default:
          return _messageFromResponse(error.response?.data) ?? fallback;
      }
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) return fallback;

    return _sanitizeUserMessage(message, fallback: fallback) ?? fallback;
  }

  static String? _messageFromResponse(dynamic data) {
    if (data is String) {
      final message = data.trim();
      return _sanitizeUserMessage(message);
    }

    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final errors = map['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages = <String>[];
      errors.forEach((key, value) {
        final text =
            value is List
                ? value.map((item) => item.toString()).join(', ')
                : value.toString();
        final sanitized = _sanitizeUserMessage(text);
        if (sanitized != null) messages.add('$key: $sanitized');
      });
      if (messages.isNotEmpty) return messages.join('\n');
    }

    final message = map['message'];
    if (message is String) {
      return _sanitizeUserMessage(message);
    }
    return null;
  }

  static String? _sanitizeUserMessage(String message, {String? fallback}) {
    var sanitized = message.trim();
    sanitized = sanitized.replaceFirst(
      RegExp(r'^\s*(?:error\s*:\s*)+', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceFirst(
      RegExp(r'^\s*[^:\n]{1,100}\s+فشل\s*:\s*'),
      '',
    );
    sanitized = sanitized.replaceFirst(
      RegExp(r'^\s*[^:\n]{1,100}\s+failed\s*:\s*', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceFirst(
      RegExp(r'^\s*status\s*:\s*', caseSensitive: false),
      '',
    );

    final lowerMessage = sanitized.toLowerCase();
    final isTechnicalOrHtml =
        sanitized.isEmpty ||
        lowerMessage.contains('<!doctype') ||
        lowerMessage.contains('<html') ||
        lowerMessage.contains('<head') ||
        lowerMessage.contains('<body') ||
        lowerMessage.contains('apache/') ||
        lowerMessage.contains('not found') ||
        lowerMessage.contains('requestoptions') ||
        lowerMessage.startsWith('dioexception') ||
        lowerMessage.contains('stack trace') ||
        lowerMessage.startsWith('exception:');

    return isTechnicalOrHtml ? fallback : sanitized;
  }

  @override
  String toString() => message;
}
