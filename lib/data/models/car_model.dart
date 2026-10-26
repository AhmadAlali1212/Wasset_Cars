import 'package:mators_car/ulits/constant.dart';

class Car {
  final int id;
  final int userId;
  final String userName;
  final String? userPhone;
  final String make;
  final String model;
  final int year;
  final String condition;
  final String description;
  final String location;
  final List<String> images;
  final List<String> videos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? mileage;
  final String? fuelType;
  final String? transmission;
  final double? latitude;
  final double? longitude;

  Car({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.condition,
    required this.description,
    required this.location,
    required this.images,
    this.videos = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
    this.userPhone,
    this.mileage,
    this.fuelType,
    this.transmission,
    this.latitude,
    this.longitude,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    List<String> parseImages(dynamic imagesJson) {
      if (imagesJson is! List) return [];
      return imagesJson
          .map((item) {
            if (item is String) return item;
            if (item is Map) {
              return (item['url'] ?? item['image_path'] ?? item['path'] ?? '')
                  .toString();
            }
            return item.toString();
          })
          .where((url) => url.isNotEmpty)
          .map((url) => AppConstants.resolveImageUrl(url) ?? url)
          .toList();
    }

    // ⬅️ جديد: نفس منطق parseImages لكن لفيديوهات السيارة الاختيارية
    List<String> parseVideos(dynamic videosJson) {
      if (videosJson is! List) return [];
      return videosJson
          .map((item) {
            if (item is String) return item;
            if (item is Map) {
              return (item['url'] ?? item['video_path'] ?? item['path'] ?? '')
                  .toString();
            }
            return item.toString();
          })
          .where((url) => url.isNotEmpty)
          .map((url) => AppConstants.resolveImageUrl(url) ?? url)
          .toList();
    }

    final userJson = json['user'];

    // رقم الهاتف الحقيقي الذي أدخله المستخدم عند إنشاء حسابه (phone_number)،
    // يصل إما ضمن كائن user المتداخل أو كحقل مباشر بجسم السيارة/الإعلان.
    String? extractPhone() {
      final direct = json['phone_number'] ?? json['phone'] ?? json['whatsapp'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }
      if (userJson is Map) {
        final p =
            userJson['phone_number'] ??
            userJson['phone'] ??
            userJson['whatsapp'];
        if (p != null && p.toString().trim().isNotEmpty) return p.toString();
      }
      return null;
    }

    int? parseIntField(List<String> keys) {
      for (final key in keys) {
        final v = json[key];
        if (v != null) return int.tryParse(v.toString());
      }
      return null;
    }

    String? parseStringField(List<String> keys) {
      for (final key in keys) {
        final v = json[key];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return null;
    }

    return Car(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      make: (json['make'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      year:
          json['year'] is int
              ? json['year']
              : int.tryParse('${json['year']}') ?? 0,
      condition: (json['condition'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      images: parseImages(json['images']),
      videos: parseVideos(json['videos']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      userName: (userJson is Map ? userJson['name'] : null) ?? '',
      userPhone: extractPhone(),
      mileage: parseIntField(['mileage', 'odometer', 'km']),
      fuelType: parseStringField(['fuel_type', 'fuel']),
      transmission: parseStringField(['transmission', 'gear_type']),
      latitude: double.tryParse('${json['latitude'] ?? ''}'),
      longitude: double.tryParse('${json['longitude'] ?? ''}'),
    );
  }

  // كائن فارغ يُستخدم كقيمة احتياطية عندما لا تتضمن استجابة الـ API بيانات السيارة
  factory Car.empty() {
    return Car(
      id: 0,
      userId: 0,
      make: '',
      model: '',
      year: 0,
      condition: '',
      description: '',
      location: '',
      images: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userName: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'make': make,
      'model': model,
      'year': year,
      'condition': condition,
      'description': description,
      'location': location,
      'images': images,
    };
  }
}
