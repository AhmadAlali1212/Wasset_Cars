import 'car_model.dart';

class Auction {
  final int id;
  final int carId;
  final String startingPrice;
  final String currentPrice;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<Bid> bids;
  final Car car;
  // معرّف واسم الفائز الحالي/النهائي بالمزاد. السيرفر قد يرسلها صراحة
  // (winner_id / winner) بعد إغلاق المزاد، وإن لم تصل فسنشتقّها احتياطياً
  // من صاحب أعلى مزايدة في القائمة.
  final int? winnerId;
  final String? winnerName;
  // حالة قرار البائع بالسعر النهائي بعد إغلاق المزاد (accepted/rejected)،
  // يصل من السيرفر كـ final_price_status. بدون هذا الحقل كانت الشاشة لا
  // تعرف أن قراراً اتُخذ فعلاً فتستمر بعرض زري القبول/الرفض حتى بعد
  // اتخاذ القرار، فيفشل أي ضغط تالٍ برسالة "تم اتخاذ قرارك مسبقاً".
  final String? finalPriceStatus;
  // من كود الـ AuctionController الفعلي: acceptFinalPrice يضبط
  // settlement_deadline_at ويُصفّر settlement_completed_at، وتأكيد إتمام
  // البيع (complete-sale) يُفترض أن يملأ settlement_completed_at، بينما
  // تراجع الفائز (winner-withdraw) يملأ winner_withdrew_at. هذان الحقلان
  // أدق من final_price_status وحده لتمييز "مكتمل" عن "متراجَع عنه" بعد
  // القبول.
  final DateTime? settlementCompletedAt;
  final DateTime? winnerWithdrewAt;

  Auction({
    required this.id,
    required this.carId,
    required this.startingPrice,
    required this.currentPrice,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.bids,
    required this.car,
    this.winnerId,
    this.winnerName,
    this.finalPriceStatus,
    this.settlementCompletedAt,
    this.winnerWithdrewAt,
  });

  // يتوافق مع الاستجابة الفعلية من الـ API (snake_case)، مع قيم احتياطية آمنة
  // بدل الانهيار عند نقص أي حقل
  factory Auction.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    String pickPrice(dynamic value) => value == null ? '0' : value.toString();

    final carJson = json['car'];
    final bids =
        json['bids'] is List
            ? (json['bids'] as List)
                .map((bid) => Bid.fromJson(Map<String, dynamic>.from(bid)))
                .toList()
            : <Bid>[];

    // محاولة قراءة الفائز صراحة من عدة أشكال محتملة للاستجابة
    final winnerJson = json['winner'];
    int? winnerId;
    String? winnerName;
    if (json['winner_id'] != null) {
      winnerId = int.tryParse('${json['winner_id']}');
    } else if (winnerJson is Map && winnerJson['id'] != null) {
      winnerId = int.tryParse('${winnerJson['id']}');
    }
    if (winnerJson is Map && winnerJson['name'] != null) {
      winnerName = winnerJson['name'].toString();
    }
    // إن لم يصل الفائز صراحة، نشتقّه من صاحب أعلى مزايدة (آخر عنصر منطقياً
    // هو الأعلى لأن المزايدات يجب أن تكون تصاعدية)
    if (winnerId == null && bids.isNotEmpty) {
      final sorted = List.of(bids)
        ..sort((a, b) {
          final av = double.tryParse(a.amount.replaceAll(',', '')) ?? 0;
          final bv = double.tryParse(b.amount.replaceAll(',', '')) ?? 0;
          return bv.compareTo(av);
        });
      winnerId = sorted.first.userId;
      winnerName = sorted.first.userName.isNotEmpty ? sorted.first.userName : winnerName;
    }

    return Auction(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      carId:
          json['car_id'] is int
              ? json['car_id']
              : int.tryParse('${json['car_id']}') ?? 0,
      startingPrice: pickPrice(json['starting_price']),
      currentPrice: pickPrice(
        json['current_price'] ?? json['highest_bid'] ?? json['starting_price'],
      ),
      startTime: parseDate(json['start_time'] ?? json['created_at']),
      endTime: parseDate(json['end_time']),
      status: (json['status'] ?? 'active').toString(),
      bids: bids,
      car: carJson is Map ? Car.fromJson(Map<String, dynamic>.from(carJson)) : Car.empty(),
      winnerId: winnerId,
      winnerName: winnerName,
      finalPriceStatus: json['final_price_status']?.toString(),
      settlementCompletedAt:
          json['settlement_completed_at'] != null
              ? DateTime.tryParse(json['settlement_completed_at'].toString())
              : null,
      winnerWithdrewAt:
          json['winner_withdrew_at'] != null
              ? DateTime.tryParse(json['winner_withdrew_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_id': carId,
      'starting_price': startingPrice,
      'current_price': currentPrice,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'bids': bids.map((bid) => bid.toJson()).toList(),
      'car': car.toJson(),
    };
  }
}

class Bid {
  final int userId;
  final String userName;
  final String amount;
  final DateTime createdAt;

  Bid({
    required this.userId,
    required this.amount,
    required this.createdAt,
    this.userName = '',
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final userJson = json['user'];

    return Bid(
      userId:
          json['user_id'] is int
              ? json['user_id']
              : int.tryParse('${json['user_id']}') ?? 0,
      amount: json['amount'] == null ? '0' : json['amount'].toString(),
      createdAt: parseDate(json['created_at']),
      userName: (userJson is Map ? userJson['name'] : null)?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
