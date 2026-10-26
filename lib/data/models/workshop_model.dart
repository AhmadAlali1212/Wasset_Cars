// models/workshop_model.dart
import 'package:mators_car/ulits/constant.dart';

class Workshop {
  final int id;
  final int userId;
  final String name;
  final String description;
  final String location;
  final List<String> services;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool featured;
  final String? phone;

  Workshop({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.location,
    required this.services,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.featured = false,
    this.phone,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'location': location,
      'services': services,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'featured': featured,
    };
  }
  factory Workshop.fromJson(Map<String, dynamic> json) {
    String? extractPhone() {
      final direct = json['phone_number'] ?? json['phone'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }
      final userObj = json['user'];
      if (userObj is Map) {
        final p = userObj['phone_number'] ?? userObj['phone'];
        if (p != null && p.toString().trim().isNotEmpty) return p.toString();
      }
      return null;
    }

    return Workshop(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      services: List<String>.from(json['services']?.map((x) => x.toString()) ?? []),
      images: List<String>.from(
        (json['images'] ?? []).map(
          (x) => AppConstants.resolveImageUrl(x) ?? x.toString(),
        ),
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      featured: json['featured'] ?? false,
      phone: extractPhone(),
    );
  }
}