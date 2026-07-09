class Car {
  final int id;
  final int userId;
  final String userName;
  final String make;
  final String model;
  final int year;
  final String condition;
  final String description;
  final String location;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      userId: json['user_id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      condition: json['condition'],
      description: json['description'],
      location: json['location'],
      images: List<String>.from(json['images']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user']?['name'] ?? '',
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