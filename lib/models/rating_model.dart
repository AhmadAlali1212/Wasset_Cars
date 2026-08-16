class Rating {
  final int id;
  final int? raterId;
  final String raterName;
  final int value; // من 1 إلى 5
  final String comment;
  final DateTime? createdAt;

  Rating({
    required this.id,
    this.raterId,
    required this.raterName,
    required this.value,
    required this.comment,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final raterObj = json['rater'] ?? json['user'] ?? json['from_user'];
    final raterName =
        (raterObj is Map ? raterObj['name'] : null) ??
        json['rater_name'] ??
        json['user_name'] ??
        'مستخدم';

    return Rating(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      raterId:
          raterObj is Map
              ? int.tryParse('${raterObj['id']}')
              : int.tryParse('${json['rater_id'] ?? json['user_id'] ?? ''}'),
      raterName: raterName.toString(),
      value:
          json['rating'] is int
              ? json['rating']
              : int.tryParse('${json['rating'] ?? json['value'] ?? 0}') ?? 0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: parseDate(json['created_at']),
    );
  }
}
