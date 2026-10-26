import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import '../api/dio_client.dart';
import '../../data/models/notification_model.dart';
import '../api_exception.dart';

// نتيجة صفحة واحدة من الإشعارات (لدعم التحميل التدريجي / pagination)
class NotificationsPage {
  final List<AppNotification> items;
  final bool hasMore;
  final int nextPage;
  final int unreadCount;

  NotificationsPage({
    required this.items,
    required this.hasMore,
    required this.nextPage,
    required this.unreadCount,
  });
}

// خدمة الإشعارات — تطابق قسم "11 - الإشعارات" في Postman:
// GET /notifications
// GET /notifications/{id}
// PATCH /notifications/{id}/read
// PATCH /notifications/read-all
// DELETE /notifications/{id}
class NotificationService {
  final Dio _dio = DioClient.instance.dio;

  // status: 'unread' أو 'read' فقط (هذه القيم يفرضها السيرفر حرفياً في
  // NotificationController@index)، أي قيمة أخرى تُهمل من طرف السيرفر.
  Future<NotificationsPage> getNotifications({
    int page = 1,
    String? status,
  }) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: {'page': page, if (status != null) 'status': status},
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب الإشعارات');
    return _parsePage(response.data);
  }

  Future<AppNotification> getNotificationDetails(String id) async {
    final response = await _dio.get(
      '/notifications/$id',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'جلب تفاصيل الإشعار');
    return AppNotification.fromJson(_normalizeResponse(response.data));
  }

  Future<void> markAsRead(String id) async {
    final response = await _dio.patch(
      '/notifications/$id/read',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تعليم الإشعار كمقروء');
  }

  Future<void> markAllAsRead() async {
    final response = await _dio.patch(
      '/notifications/read-all',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'تعليم جميع الإشعارات كمقروءة');
  }

  Future<void> deleteNotification(String id) async {
    final response = await _dio.delete(
      '/notifications/$id',
      options: await _authOptions(),
    );
    _handleResponseErrors(response, 'حذف الإشعار');
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }

  // يدعم عدة أشكال محتملة للاستجابة:
  // { notifications: { data: [...], current_page, last_page, unread_count } }
  // { notifications: [...] }
  // { data: [...] }
  // [...]
  NotificationsPage _parsePage(dynamic raw) {
    dynamic container = raw;
    if (raw is Map && raw['notifications'] != null) {
      container = raw['notifications'];
    }

    List rows = [];
    bool hasMore = false;
    int nextPage = 2;
    int unreadCount = 0;

    if (container is List) {
      rows = container;
    } else if (container is Map) {
      final data = container['data'];
      if (data is List) {
        rows = data;
        final currentPage = _toInt(container['current_page']) ?? 1;
        final lastPage = _toInt(container['last_page']);
        if (lastPage != null) {
          hasMore = currentPage < lastPage;
          nextPage = currentPage + 1;
        } else {
          final nextUrl = container['next_page_url'];
          hasMore = nextUrl != null;
          nextPage = currentPage + 1;
        }
      } else {
        rows = _extractList(container);
      }
      unreadCount =
          _toInt(container['unread_count']) ??
          _toInt((raw is Map) ? raw['unread_count'] : null) ??
          0;
    }

    final items =
        rows
            .whereType<Map>()
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    if (unreadCount == 0) {
      unreadCount = items.where((n) => !n.isRead).length;
    }

    return NotificationsPage(
      items: items,
      hasMore: hasMore,
      nextPage: nextPage,
      unreadCount: unreadCount,
    );
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'items', 'results']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    return [];
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map && data['notification'] is Map) {
      return Map<String, dynamic>.from(data['notification'] as Map);
    }
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return;
    }
    final message = _extractValidationMessage(response.data);
    throw ApiException(
      '$operation فشل: $message',
      statusCode: response.statusCode,
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
