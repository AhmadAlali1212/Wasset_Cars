class Promotion {
  final int id;
  final int? ownerId;
  final String? ownerName;
  final String title;
  final String description;
  final String type;
  final double value;
  final DateTime? startDate;
  final DateTime? endDate;
  final int quantity;
  final String status; // pending / approved / rejected (اعتماد الإدارة)
  final String? rejectionReason;

  Promotion({
    required this.id,
    this.ownerId,
    this.ownerName,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.quantity,
    required this.status,
    this.rejectionReason,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // اسم حقل المالك قد يختلف (user_id للفرد، company_id للشركة)، أو
    // كائن user متداخل، لذلك نتحقق من عدة احتمالات.
    int? parseOwnerId() {
      final direct =
          json['user_id'] ?? json['company_id'] ?? json['owner_id'];
      if (direct != null) return int.tryParse('$direct');
      final userObj = json['user'] ?? json['company'];
      if (userObj is Map) return int.tryParse('${userObj['id']}');
      return null;
    }

    String? parseOwnerName() {
      final userObj = json['user'] ?? json['company'];
      if (userObj is Map) {
        final name =
            userObj['company_name'] ?? userObj['name'] ?? userObj['full_name'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }
      final direct = json['company_name'] ?? json['owner_name'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
      return null;
    }

    return Promotion(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      ownerId: parseOwnerId(),
      ownerName: parseOwnerName(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'discount').toString(),
      value: double.tryParse('${json['value'] ?? 0}') ?? 0,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      quantity:
          json['quantity'] is int
              ? json['quantity']
              : int.tryParse('${json['quantity'] ?? 0}') ?? 0,
      status: (json['status'] ?? json['approval_status'] ?? 'approved')
          .toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  bool get isUpcoming =>
      startDate != null && startDate!.isAfter(DateTime.now());

  // عرض "نشط فعلياً" أي معتمد + ضمن الفترة الزمنية (لا منتهي ولا لم يبدأ بعد)
  bool get isActiveNow =>
      status == 'approved' && !isExpired && !isUpcoming;

  int get daysRemaining {
    if (endDate == null) return 0;
    final diff = endDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
