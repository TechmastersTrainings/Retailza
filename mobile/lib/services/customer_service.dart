import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/customer_model.dart';

class CustomerService {
  Future<List<CustomerModel>> getCustomers({String? search, bool hasBalanceOnly = false}) async {
    final Map<String, String> query = {};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (hasBalanceOnly) query['has_balance_only'] = 'true';

    final response = await ApiClient.get(ApiConstants.customers, queryParams: query);
    final list = response as List<dynamic>;
    return list.map((c) => CustomerModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<CustomerModel> createCustomer(String name, String? mobileNumber) async {
    final response = await ApiClient.post(
      ApiConstants.customers,
      body: {
        'name': name,
        if (mobileNumber != null && mobileNumber.isNotEmpty) 'mobile_number': mobileNumber,
      },
    );
    return CustomerModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CustomerModel> getCustomerDetails(int customerId) async {
    final response = await ApiClient.get("${ApiConstants.customers}/$customerId");
    return CustomerModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CustomerModel> recordCreditPayment(int customerId, double amount, {String? note}) async {
    final response = await ApiClient.post(
      "${ApiConstants.customers}/$customerId/credit-payment",
      body: {
        'amount': amount,
        if (note != null) 'note': note,
      },
    );
    return CustomerModel.fromJson(response as Map<String, dynamic>);
  }
}
