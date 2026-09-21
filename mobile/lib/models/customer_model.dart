class CreditTransactionModel {
  final int id;
  final int customerId;
  final int? saleId;
  final double amount;
  final String transactionType;
  final String? note;
  final DateTime createdAt;

  CreditTransactionModel({
    required this.id,
    required this.customerId,
    this.saleId,
    required this.amount,
    required this.transactionType,
    this.note,
    required this.createdAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      saleId: json['sale_id'] as int?,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      transactionType: json['transaction_type'] as String,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class CustomerModel {
  final int id;
  final int shopId;
  final String name;
  final String? mobileNumber;
  final double balance;
  final List<CreditTransactionModel> recentTransactions;

  CustomerModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.mobileNumber,
    required this.balance,
    this.recentTransactions = const [],
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    var rawTx = json['recent_transactions'] as List<dynamic>? ?? [];
    List<CreditTransactionModel> txs =
        rawTx.map((t) => CreditTransactionModel.fromJson(t as Map<String, dynamic>)).toList();

    return CustomerModel(
      id: json['id'] as int,
      shopId: json['shop_id'] as int,
      name: json['name'] as String,
      mobileNumber: json['mobile_number'] as String?,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      recentTransactions: txs,
    );
  }
}
