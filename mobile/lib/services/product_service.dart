import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<ProductModel>> getProducts({
    String? search,
    String? category,
    bool lowStockOnly = false,
  }) async {
    final Map<String, String> query = {};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (category != null && category != 'All') query['category'] = category;
    if (lowStockOnly) query['low_stock_only'] = 'true';

    final response = await ApiClient.get(ApiConstants.products, queryParams: query);
    final list = response as List<dynamic>;
    return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> getProductByBarcode(String barcode) async {
    final response = await ApiClient.get("${ApiConstants.barcodeSearch}/$barcode");
    return ProductModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response = await ApiClient.post(ApiConstants.products, body: data);
    return ProductModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.put("${ApiConstants.products}/$id", body: data);
    return ProductModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    await ApiClient.delete("${ApiConstants.products}/$id");
  }

  Future<ProductModel> restock(int productId, double quantity, {String? reason}) async {
    final response = await ApiClient.post(
      "${ApiConstants.inventory}/$productId/restock?quantity=$quantity${reason != null ? '&reason=$reason' : ''}",
    );
    return ProductModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductModel> adjustStock(int productId, double changeQuantity, {String? reason}) async {
    final response = await ApiClient.post(
      "${ApiConstants.inventory}/$productId/adjust",
      body: {
        'change_quantity': changeQuantity,
        'transaction_type': 'ADJUSTMENT',
        'reason': reason ?? 'Manual adjustment',
      },
    );
    return ProductModel.fromJson(response as Map<String, dynamic>);
  }
}
