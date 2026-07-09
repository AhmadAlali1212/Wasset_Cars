import 'car_model.dart';

class Auction {
  final int id;
  final int adId;
  final String startingPrice;
  final String currentPrice;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<Bid> bids;
  final Car car;

  Auction({
    required this.id,
    required this.adId,
    required this.startingPrice,
    required this.currentPrice,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.bids,
    required this.car,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id'],
      adId: json['adId'],
      startingPrice: json['startingPrice'],
      currentPrice: json['currentPrice'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'],
      bids: (json['bids'] as List<dynamic>)
          .map((bid) => Bid.fromJson(bid))
          .toList(),
      car: Car.fromJson(json['car']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adId': adId,
      'startingPrice': startingPrice,
      'currentPrice': currentPrice,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'bids': bids.map((bid) => bid.toJson()).toList(),
      'car': car.toJson(),
    };
  }
}

class Bid {
  final int userId;
  final String amount;
  final DateTime createdAt;

  Bid({
    required this.userId,
    required this.amount,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      userId: json['userId'],
      amount: json['amount'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}