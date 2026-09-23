class SubscriptionModel {
  final int id;
  final int shopId;
  final String planName;
  final double amount;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  SubscriptionModel({
    required this.id,
    required this.shopId,
    required this.planName,
    required this.amount,
    required this.status,
    this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as int,
      shopId: json['shop_id'] as int,
      planName: json['plan_name'] as String? ?? 'basic',
      amount: double.tryParse(json['amount'].toString()) ?? 49.0,
      status: json['status'] as String? ?? 'PENDING',
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'plan_name': planName,
      'amount': amount,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
