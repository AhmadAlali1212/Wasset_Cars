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
    this.dailyPrice = '',
    this.monthlyPrice = '',
    this.rentalConditions = '',
    this.location = '',
  });

  // من JSON إلى كائن Ad
  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'],
      carId: json['carId'],
      userId: json['userId'],
      price: json['price'] ?? '',
      status: json['status'],
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      car: Car.fromJson(json['car']),
      auctions: (json['auctions'] as List<dynamic>)
          .map((auction) => Auction.fromJson(auction))
          .toList(),
      dailyPrice: json['dailyPrice'] ?? '',
      monthlyPrice: json['monthlyPrice'] ?? '',
      rentalConditions: json['rentalConditions'] ?? '',
      location: json['location'] ?? '',
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