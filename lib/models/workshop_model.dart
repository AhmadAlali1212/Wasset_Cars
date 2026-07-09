// models/workshop_model.dart
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
    return Workshop(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      services: List<String>.from(json['services']?.map((x) => x.toString()) ?? []),
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      featured: json['featured'] ?? false,


    );
  }
}