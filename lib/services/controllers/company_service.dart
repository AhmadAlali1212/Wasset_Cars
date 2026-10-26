import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mators_car/data/dataSource/remote/company/company_data.dart';

class CompanyService {
  final CompanyData _data = CompanyData();

  // قائمة سياراتي الكاملة (my-cars) — تختلف عن /cars وهي القائمة العامة
  Future<List<Map<String, dynamic>>> getMyCars() async {
    final response = await _data.getMyCars();
    _handleResponseErrors(response, 'جلب سياراتي');
    return _normalizeCarsResponse(response.data);
  }

  Future<List<Map<String, dynamic>>> getCompanyCars() async {
    return getMyCars();
  }

  // تفاصيل سيارة من سياراتي بالكامل (my-cars/{car_id})
  Future<Map<String, dynamic>> getMyCarDetails(int carId) async {
    final response = await _data.getMyCarDetails(carId);
    _handleResponseErrors(response, 'جلب تفاصيل السيارة');
    return _normalizeResponse(response.data);
  }

  // قائمة السيارات العامة (cars) — متاحة لأي مستخدم مسجل، بدون فلترة على الحالة
  Future<List<Map<String, dynamic>>> getPublicCars() async {
    final response = await _data.getPublicCars();
    _handleResponseErrors(response, 'جلب قائمة السيارات العامة');
    return _normalizeCarsResponse(response.data);
  }

  // قائمة سيارات باقي المستخدمين (باستثناء سياراتي)
  Future<List<Map<String, dynamic>>> getOtherUsersCars() async {
    final response = await _data.getOtherUsersCars();
    _handleResponseErrors(response, 'جلب سيارات المستخدمين الآخرين');
    return _normalizeCarsResponse(response.data);
  }

  // تفاصيل سيارة عامة تخص مستخدماً آخر (cars/{public_car_id})
  Future<Map<String, dynamic>> getPublicCarDetails(int carId) async {
    final response = await _data.getPublicCarDetails(carId);
    _handleResponseErrors(response, 'جلب تفاصيل السيارة');
    return _normalizeResponse(response.data);
  }

  // تفاصيل السيارة حسب الصلاحية: يعيد بيانات كاملة إذا كنت المالك أو بيانات عامة إن لم تكن
  Future<Map<String, dynamic>> getCarDetails(int carId) async {
    final response = await _data.getCarDetails(carId);
    _handleResponseErrors(response, 'جلب تفاصيل السيارة');
    return _normalizeResponse(response.data);
  }

  // تعديل بيانات سيارة بدون تغيير الصور (PUT /cars/{car_id})
  // تعديل بيانات السيارة. حسب توثيق الـ API: التعديل بدون صور يُرسل كـ
  // JSON عادي (PUT)، أما تعديل الصور فيتطلب multipart/form-data. بما أن
  // PHP/Laravel لا يدعم قراءة multipart مباشرة مع فعل PUT، نستخدم POST
  // مع حقل _method=PUT (الأسلوب القياسي المعروف بـ method spoofing).
  Future<Map<String, dynamic>> updateCar({
    required int carId,
    required Map<String, dynamic> fields,
    List<File>? newImageFiles,
  }) async {
    final response = await _data.updateCar(
      carId: carId,
      fields: fields,
      newImageFiles: newImageFiles,
    );

    _handleResponseErrors(response, 'تعديل بيانات السيارة');
    return _normalizeResponse(response.data);
  }

  Future<List<Map<String, dynamic>>> getAllCars() async {
    final response = await _data.getAllCars();
    _handleResponseErrors(response, 'جلب جميع السيارات');
    return _normalizeAdsResponse(response.data);
  }

  Future<Map<String, dynamic>> getWallet() async {
    final response = await _data.getWallet();
    _handleResponseErrors(response, 'جلب المحفظة');
    return _normalizeWalletResponse(response.data);
  }

  // إنشاء Stripe PaymentIntent لشحن المحفظة (POST /wallet/stripe/create-intent)
  // تُعيد client_secret و request_id اللازمين لإتمام الدفع عبر Stripe SDK على الجهاز
  Future<Map<String, dynamic>> createStripeTopupIntent({
    required double amountUsd,
    String? requestId,
  }) async {
    final response = await _data.createStripeTopupIntent(
      amountUsd: amountUsd,
      requestId: requestId,
    );
    _handleResponseErrors(response, 'إنشاء عملية شحن Stripe');
    return _normalizeResponse(response.data);
  }

  // متابعة حالة طلب شحن Stripe (GET /wallet/stripe/topups/{id})
  Future<Map<String, dynamic>> getStripeTopupStatus(String requestId) async {
    final response = await _data.getStripeTopupStatus(requestId);
    _handleResponseErrors(response, 'التحقق من حالة الشحن');
    return _normalizeResponse(response.data);
  }

  // طلب سحب من المحفظة (destination إلزامي حسب الـ API: رقم/عنوان جهة السحب)
  Future<Map<String, dynamic>> withdrawWallet({
    required double amount,
    required String withdrawalMethod,
    required String destination,
  }) async {
    final response = await _data.withdrawWallet(
      amount: amount,
      withdrawalMethod: withdrawalMethod,
      destination: destination,
    );
    _handleResponseErrors(response, 'سحب من المحفظة');
    return _normalizeWalletResponse(response.data);
  }

  Future<Map<String, dynamic>> addCar({
    required Map<String, dynamic> fields,
    List<File>? imageFiles,
    // ⬅️ جديد: فيديوهات اختيارية عند إنشاء السيارة (بحد أقصى 2)
    List<File>? videoFiles,
  }) async {
    final response = await _data.addCar(
      fields: fields,
      imageFiles: imageFiles,
      videoFiles: videoFiles,
    );

    _handleResponseErrors(response, 'إضافة سيارة جديدة');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ⬅️ جديد: رفع فيديو (أو أكثر) لسيارة موجودة مسبقاً — يغطي حالة "أريد
  // رفعه لاحقاً" بدل الاكتفاء بوقت إنشاء السيارة فقط.
  Future<List<String>> addCarVideos({
    required int carId,
    required List<File> videoFiles,
  }) async {
    final response = await _data.addCarVideos(
      carId: carId,
      videoFiles: videoFiles,
    );

    _handleResponseErrors(response, 'رفع فيديو السيارة');
    final data = response.data;
    if (data is Map && data['videos'] is List) {
      return List<String>.from(data['videos'].map((e) => e.toString()));
    }
    return [];
  }

  // ⬅️ جديد: حذف فيديو واحد من سيارة (بمعرفة رابطه بالضبط)
  Future<List<String>> removeCarVideo({
    required int carId,
    required String videoUrl,
  }) async {
    final response = await _data.removeCarVideo(
      carId: carId,
      videoUrl: videoUrl,
    );

    _handleResponseErrors(response, 'حذف فيديو السيارة');
    final data = response.data;
    if (data is Map && data['videos'] is List) {
      return List<String>.from(data['videos'].map((e) => e.toString()));
    }
    return [];
  }

  Future<Map<String, dynamic>> requestInspection(int carId) async {
    final response = await _data.requestInspection(carId);
    _handleResponseErrors(response, 'طلب الفحص الفني');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteCar(int carId) async {
    final response = await _data.deleteCar(carId);
    _handleResponseErrors(response, 'حذف السيارة');
  }

  List<Map<String, dynamic>> _normalizeCarsResponse(dynamic data) {
    final list = _extractList(data);
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // يبحث بعمق عن أول قائمة (List) ضمن مفاتيح شائعة (data/cars/ads/items/results)
  // بغض النظر عن عدد مستويات التغليف (مثلاً {"cars": {"data": [...]}})
  // هذا يعالج مشكلة ظهور قوائم فارغة رغم وجود بيانات فعلية بسبب اختلاف شكل
  // تغليف استجابة الـ API (pagination متداخل تحت مفتاح مخصص).
  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'cars', 'ads', 'items', 'results']) {
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

  List<Map<String, dynamic>> _normalizeAdsResponse(dynamic data) {
    final items = _normalizeCarsResponse(data);
    return items.map((item) {
      final car = item['car'];
      if (car is Map) {
        final normalized = Map<String, dynamic>.from(car);
        normalized['ad_id'] = item['id'];
        normalized['price'] = item['price'];
        normalized['status'] = item['status'] ?? normalized['status'];
        normalized['owner'] =
            item['owner'] ?? item['user'] ?? normalized['owner'];
        return normalized;
      }
      return item;
    }).toList();
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data is Map && data['car'] is Map) {
      return Map<String, dynamic>.from(data['car'] as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Map<String, dynamic> _normalizeWalletResponse(dynamic data) {
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
    final details = <String>[];

    if (response.statusCode != null) {
      details.add('رمز الحالة: ${response.statusCode}');
    }

    if (response.statusMessage != null &&
        response.statusMessage!.trim().isNotEmpty) {
      details.add(response.statusMessage!.trim());
    }

    final detailText = details.isNotEmpty ? details.join(' - ') : null;
    final fullMessage =
        detailText != null && message != 'حدث خطأ غير معروف'
            ? '$operation فشل: $message\n$detailText'
            : '$operation فشل: $message';

    throw Exception(fullMessage);
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
