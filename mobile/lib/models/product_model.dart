class ProductModel {
  final int id;
  final int shopId;
  final String name;
  final String? barcode;
  final String category;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double stockQuantity;
  final double minStockThreshold;
  final bool isActive;
  final bool isLowStock;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.barcode,
    required this.category,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minStockThreshold,
    required this.isActive,
    required this.isLowStock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      shopId: json['shop_id'] as int,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      category: json['category'] as String? ?? 'General',
      unit: json['unit'] as String? ?? 'piece',
      purchasePrice: double.tryParse(json['purchase_price'].toString()) ?? 0.0,
      sellingPrice: double.tryParse(json['selling_price'].toString()) ?? 0.0,
      stockQuantity: double.tryParse(json['stock_quantity'].toString()) ?? 0.0,
      minStockThreshold: double.tryParse(json['min_stock_threshold'].toString()) ?? 5.0,
      isActive: json['is_active'] as bool? ?? true,
      isLowStock: json['is_low_stock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'barcode': barcode,
      'category': category,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'min_stock_threshold': minStockThreshold,
      'is_active': isActive,
    };
  }
}
