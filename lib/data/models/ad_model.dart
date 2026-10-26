import 'auction_model.dart';
import 'car_model.dart';

class Ad {
  final int id;
  final int carId;
  final int userId;
  final String price;
  final String status;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Car car;
  final List<Auction> auctions;
  final String sellerName;
  final String? sellerPhone;

  // حقول التأجير
  final String dailyPrice;
  final String monthlyPrice;
  final String rentalConditions;
  final String location;

  Ad({
    required this.id,
    required this.carId,
    required this.userId,
    required this.price,
    required this.status,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    required this.car,
    required this.auctions,
    this.sellerName = '',
    this.sellerPhone,
    this.dailyPrice = '',
    this.monthlyPrice = '',
    this.rentalConditions = '',
    this.location = '',
  });

  // من JSON إلى كائن Ad
  // تدعم هذه الدالة صيغتين:
  // 1) الصيغة الحقيقية القادمة من الـ API (snake_case): car_id, user_id,
  //    daily_price, monthly_price, rental_conditions, created_at, updated_at...
  // 2) الصيغة القديمة المستخدمة في mock_data.dart (camelCase) للحفاظ على التوافق.
  factory Ad.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final carJson = json['car'];
    final auctionsJson = json['auctions'];
    // بيانات البائع تصل كحقل منفصل على مستوى الإعلان وليس داخل السيارة
    // (seller: {id, name, phone}) في استجابة إعلانات المستخدمين الآخرين،
    // وقد تصل أيضاً باسم "user" في بعض الاستجابات — نتحقق من الاثنين.
    final sellerJson = json['seller'] ?? json['user'];
    String sellerName = '';
    String? sellerPhone;
    if (sellerJson is Map) {
      sellerName = (sellerJson['name'] ?? '').toString();
      final phone =
          sellerJson['phone'] ??
          sellerJson['phone_number'] ??
          sellerJson['whatsapp'];
      if (phone != null && phone.toString().trim().isNotEmpty) {
        sellerPhone = phone.toString();
      }
    }

    return Ad(
      id: pick(['id']) ?? 0,
      carId: pick(['car_id', 'carId']) ?? 0,
      userId: pick(['user_id', 'userId']) ?? 0,
      price: (pick(['price']) ?? '').toString(),
      status: (pick(['status']) ?? '').toString(),
      isFeatured: pick(['is_featured', 'isFeatured']) ?? false,
      createdAt: parseDate(pick(['created_at', 'createdAt'])),
      updatedAt: parseDate(pick(['updated_at', 'updatedAt'])),
      car: carJson is Map ? Car.fromJson(Map<String, dynamic>.from(carJson)) : Car.empty(),
      auctions:
          auctionsJson is List
              ? auctionsJson
                  .whereType<Map>()
                  .map((auction) => Auction.fromJson(Map<String, dynamic>.from(auction)))
                  .toList()
              : [],
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      dailyPrice: (pick(['daily_price', 'dailyPrice']) ?? '').toString(),
      monthlyPrice: (pick(['monthly_price', 'monthlyPrice']) ?? '').toString(),
      rentalConditions: (pick(['rental_conditions', 'rentalConditions']) ?? '').toString(),
      location: (pick(['location']) ?? (carJson is Map ? carJson['location'] : null) ?? '').toString(),
    );
  }

  // رقم هاتف يمكن استخدامه فعلياً للاتصال/الدردشة: نفضّل بيانات البائع على
  // مستوى الإعلان، ونرجع لبيانات السيارة كحل احتياطي (لتوافق استجابات أخرى
  // قد تُرفق user داخل car مباشرة، مثل /my-cars).
  String? get contactPhone => sellerPhone ?? car.userPhone;
  String get contactName => sellerName.isNotEmpty ? sellerName : car.userName;

  Ad copyWith({bool? isFeatured}) {
    return Ad(
      id: id,
      carId: carId,
      userId: userId,
      price: price,
      status: status,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt,
      updatedAt: updatedAt,
      car: car,
      auctions: auctions,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      dailyPrice: dailyPrice,
      monthlyPrice: monthlyPrice,
      rentalConditions: rentalConditions,
      location: location,
    );
  }

  // يُستخدم عند دمج استجابة تفاصيل لا تحتوي على كائن السيارة المتداخل
  // (مثل GET /rental-ads/{id}) مع بيانات سيارة موثوقة وصلت مسبقاً من
  // شاشة القائمة، حتى لا تختفي الصور/الموديل/الموقع بعد أول تحديث.
  Ad withCar(Car replacementCar) {
    return Ad(
      id: id,
      carId: carId,
      userId: userId,
      price: price,
      status: status,
      isFeatured: isFeatured,
      createdAt: createdAt,
      updatedAt: updatedAt,
      car: replacementCar,
      auctions: auctions,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      dailyPrice: dailyPrice,
      monthlyPrice: monthlyPrice,
      rentalConditions: rentalConditions,
      location: location,
    );
  }

  // من كائن Ad إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carId': carId,
      'userId': userId,
      'price': price,
      'status': status,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'car': car.toJson(),
      'auctions': auctions.map((auction) => auction.toJson()).toList(),
      'dailyPrice': dailyPrice,
      'monthlyPrice': monthlyPrice,
      'rentalConditions': rentalConditions,
      'location': location,
    };
  }
}