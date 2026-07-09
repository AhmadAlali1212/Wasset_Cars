class Subscription {
  final int id;
  final int userId;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int transactionId;

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
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      amount: double.parse(json['amount'].toString()),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
      transactionId: json['transaction_id'],
    );
  }
}