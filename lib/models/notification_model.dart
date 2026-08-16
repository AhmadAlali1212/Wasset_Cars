// نموذج الإشعار — يطابق جدول notifications الافتراضي في Laravel:
// id (uuid), type (اسم كلاس الإشعار الكامل غالباً)، data (JSON حر)،
// read_at، created_at. بما أن حقل "data" حر الشكل من طرف السيرفر، هذا
// النموذج يحاول قراءة العنوان/النص من عدة مفاتيح محتملة بدل الاعتماد
// على بنية واحدة صارمة، حتى يبقى متوافقاً مع أي تغيير بسيط في الـ API.
class AppNotification {
  final String id;
  final String rawType;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.rawType,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic> extractData() {
      final rawData = json['data'];
      if (rawData is Map) return Map<String, dynamic>.from(rawData);
      return {};
    }

    final data = extractData();
    final rawType = (json['type'] ?? data['type'] ?? '').toString();

    String pick(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final fromData = data[key];
        if (fromData is String && fromData.trim().isNotEmpty) {
          return fromData.trim();
        }
        final fromJson = json[key];
        if (fromJson is String && fromJson.trim().isNotEmpty) {
          return fromJson.trim();
        }
      }
      return fallback;
    }

    return AppNotification(
      id: (json['id'] ?? '').toString(),
      rawType: rawType,
      title: pick(['title'], fallback: _titleFromType(rawType)),
      body: pick(['message', 'body', 'description', 'text']),
      data: data,
      readAt: parseNullableDate(json['read_at']),
      createdAt: parseDate(json['created_at']),
    );
  }

  static String _titleFromType(String rawType) {
    final t = rawType.toLowerCase();
    if (t.contains('auction')) return 'إشعار مزاد';
    if (t.contains('order') || t.contains('booking')) return 'إشعار طلب';
    if (t.contains('promotion') || t.contains('offer')) return 'عرض جديد';
    return 'إشعار جديد';
  }

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
      id: id,
      rawType: rawType,
      title: title,
      body: body,
      data: data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

// تصنيفات الإشعار المستخدمة لتبويبات الفلترة أعلى الشاشة
enum NotificationCategory { system, offer, order, auction }

extension NotificationCategoryX on AppNotification {
  NotificationCategory get category {
    final text = '$rawType $title $body'.toLowerCase();
    if (text.contains('auction') ||
        text.contains('bid') ||
        text.contains('مزاد') ||
        text.contains('مزايد')) {
      return NotificationCategory.auction;
    }
    if (text.contains('promotion') ||
        text.contains('promo') ||
        text.contains('offer') ||
        text.contains('discount') ||
        text.contains('coupon') ||
        text.contains('عرض') ||
        text.contains('خصم') ||
        text.contains('كوبون')) {
      return NotificationCategory.offer;
    }
    if (text.contains('order') ||
        text.contains('booking') ||
        text.contains('reservation') ||
        text.contains('request') ||
        text.contains('rental') ||
        text.contains('طلب') ||
        text.contains('حجز') ||
        text.contains('تأجير')) {
      return NotificationCategory.order;
    }
    return NotificationCategory.system;
  }
}
