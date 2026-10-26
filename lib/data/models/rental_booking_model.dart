import 'ad_model.dart';

// نموذج حجز تأجير — يطابق استجابة POST /rental-bookings و GET /rental-bookings/my.
// لا يوفّر توثيق الـ API شكل الاستجابة بالتفصيل، لذلك تعتمد القراءة هنا على
// عدة مفاتيح محتملة مع قيم احتياطية آمنة بدل الانهيار عند نقص أي حقل.
class RentalBooking {
  final int id;
  final int rentalAdId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String totalPrice;
  final DateTime createdAt;
  // ⬅️ جديد: تتبع تسليم/إرجاع حقيقي من السيرفر (بدل الحل المحلي السابق)
  final DateTime? deliveredAt;
  final DateTime? returnedAt;
  final String? rejectionReason;
  // بيانات المستأجر (تصل ضمن الطلبات الواردة على المالك فقط)
  final int? renterId;
  final String? renterName;
  final String? renterPhone;
  // إعلان التأجير المتداخل إن وصل ضمن الاستجابة (لعرض صورة/اسم السيارة
  // ومعلومات المالك)، وإلا يبقى null ونعرض بيانات أساسية فقط.
  final Ad? rentalAd;

  RentalBooking({
    required this.id,
    required this.rentalAdId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.deliveredAt,
    this.returnedAt,
    this.rejectionReason,
    this.renterId,
    this.renterName,
    this.renterPhone,
    this.rentalAd,
  });

  factory RentalBooking.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    int parseInt(dynamic value) =>
        value is int ? value : int.tryParse('${value ?? ''}') ?? 0;

    final nestedAdJson =
        json['rental_ad'] ?? json['rentalAd'] ?? json['ad'];
    final nestedUserJson = json['user'] ?? json['renter'];
    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return RentalBooking(
      id: parseInt(json['id']),
      rentalAdId: parseInt(json['rental_ad_id'] ?? json['rentalAdId']),
      startDate: parseDate(json['start_date'] ?? json['startDate']),
      endDate: parseDate(json['end_date'] ?? json['endDate']),
      status: (json['status'] ?? 'confirmed').toString(),
      totalPrice:
          (json['total_price'] ?? json['price'] ?? json['amount'] ?? '')
              .toString(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      deliveredAt: parseOptionalDate(json['delivered_at'] ?? json['deliveredAt']),
      returnedAt: parseOptionalDate(json['returned_at'] ?? json['returnedAt']),
      rejectionReason: json['rejection_reason']?.toString(),
      renterId: nestedUserJson is Map ? parseInt(nestedUserJson['id']) : null,
      renterName: nestedUserJson is Map ? nestedUserJson['name']?.toString() : null,
      renterPhone:
          nestedUserJson is Map
              ? (nestedUserJson['phone_number'] ?? nestedUserJson['phone'])?.toString()
              : null,
      rentalAd:
          nestedAdJson is Map
              ? Ad.fromJson(Map<String, dynamic>.from(nestedAdJson))
              : null,
    );
  }

  int get durationDays => endDate.difference(startDate).inDays;

  bool get hasStarted => !startDate.isAfter(DateTime.now());
  bool get hasEnded => !endDate.isAfter(DateTime.now());
}
