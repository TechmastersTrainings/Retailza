import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  Future<SubscriptionModel> getCurrentSubscription() async {
    final response = await ApiClient.get(ApiConstants.currentSubscription);
    return SubscriptionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createOrder() async {
    final response = await ApiClient.post(ApiConstants.createSubscriptionOrder);
    return response as Map<String, dynamic>;
  }

  Future<SubscriptionModel> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.verifySubscriptionPayment,
      body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return SubscriptionModel.fromJson(response as Map<String, dynamic>);
  }
}
