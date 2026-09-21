class SaleItemModel {
  final int id;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  SaleItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
    );
  }
}

class SaleModel {
  final int id;
  final int shopId;
  final int? customerId;
  final String? customerName;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final String paymentMode;
  final String paymentStatus;
  final double profit;
  final String status;
  final DateTime createdAt;
  final List<SaleItemModel> items;

  SaleModel({
    required this.id,
    required this.shopId,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.paymentMode,
    this.paymentStatus = 'PAID',
    this.profit = 0.0,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<SaleItemModel> parsedItems =
        rawItems.map((item) => SaleItemModel.fromJson(item as Map<String, dynamic>)).toList();

    return SaleModel(
      id: json['id'] as int,
      shopId: json['shop_id'] as int,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      finalAmount: double.tryParse(json['final_amount'].toString()) ?? 0.0,
      paymentMode: json['payment_mode'] as String? ?? 'CASH',
      paymentStatus: json['payment_status'] as String? ?? 'PAID',
      profit: double.tryParse(json['profit'].toString()) ?? 0.0,
      status: json['status'] as String? ?? 'COMPLETED',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      items: parsedItems,
    );
  }
}
