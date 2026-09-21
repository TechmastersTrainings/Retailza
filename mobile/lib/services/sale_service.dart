import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/sale_model.dart';

class SaleService {
  Future<SaleModel> checkout({
    int? customerId,
    required double discount,
    required String paymentMode,
    String paymentStatus = 'PAID',
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      if (customerId != null) 'customer_id': customerId,
      'discount': discount,
      'payment_mode': paymentMode,
      'payment_status': paymentStatus,
      'items': items,
    };

    final response = await ApiClient.post(ApiConstants.checkout, body: body);
    return SaleModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<SaleModel>> getSales({
    String? paymentMode,
    int? customerId,
    String? saleDate,
  }) async {
    final Map<String, String> params = {};
    if (paymentMode != null && paymentMode.isNotEmpty) params['payment_mode'] = paymentMode;
    if (customerId != null) params['customer_id'] = customerId.toString();
    if (saleDate != null) params['sale_date'] = saleDate;

    final response = await ApiClient.get(ApiConstants.sales, queryParams: params);
    final list = response as List<dynamic>;
    return list.map((s) => SaleModel.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<SaleModel> getSaleDetail(int saleId) async {
    final response = await ApiClient.get("${ApiConstants.sales}/$saleId");
    return SaleModel.fromJson(response as Map<String, dynamic>);
  }
}
