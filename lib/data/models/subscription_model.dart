class Subscription {
  final int id;
  final int userId;
  final double amount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int? transactionId;

  Subscription({
    required this.id,
    required this.userId,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.transactionId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return Subscription(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      userId:
          json['user_id'] is int
              ? json['user_id']
              : int.tryParse('${json['user_id']}') ?? 0,
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      status: (json['status'] ?? 'inactive').toString(),
      transactionId:
          json['transaction_id'] == null
              ? null
              : int.tryParse('${json['transaction_id']}'),
    );
  }
}
