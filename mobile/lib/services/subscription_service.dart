import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/subscription_model.dart';

/// UPI Gateway payment order for the subscription fee.
class SubscriptionPaymentOrder {
  final String orderId;
  final double amount;
  final String paymentUrl;
  final String? upiIntent;
  final DateTime? expiresAt;
  final bool isTest;

  SubscriptionPaymentOrder({
    required this.orderId,
    required this.amount,
    required this.paymentUrl,
    this.upiIntent,
    this.expiresAt,
    this.isTest = false,
  });

  factory SubscriptionPaymentOrder.fromJson(Map<String, dynamic> json) {
    final intent = json['upi_intent'] as String?;
    final expires = json['expires_at'] as String?;
    return SubscriptionPaymentOrder(
      orderId: json['order_id'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentUrl: json['payment_url'] as String,
      upiIntent: (intent != null && intent.isNotEmpty) ? intent : null,
      expiresAt: expires != null ? DateTime.tryParse(expires) : null,
      isTest: json['test'] as bool? ?? false,
    );
  }
}

/// Server-verified payment status. Only the backend (asking the gateway)
/// can report SUCCESS; the app never decides a payment is paid.
class SubscriptionPaymentStatus {
  /// PENDING, REVIEW, SUCCESS, EXPIRED or FAILED
  final String status;
  final String? message;
  final SubscriptionModel subscription;

  SubscriptionPaymentStatus({required this.status, this.message, required this.subscription});

  bool get isPaid => status == 'SUCCESS';
  bool get isFinalFailure => status == 'FAILED';

  factory SubscriptionPaymentStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentStatus(
      status: json['status'] as String? ?? 'PENDING',
      message: json['message'] as String?,
      subscription: SubscriptionModel.fromJson(json['subscription'] as Map<String, dynamic>),
    );
  }
}

class SubscriptionService {
  Future<SubscriptionModel> getCurrentSubscription() async {
    final response = await ApiClient.get(ApiConstants.currentSubscription);
    final map = response as Map<String, dynamic>;
    await ApiClient.saveCachedSubscription(map);
    return SubscriptionModel.fromJson(map);
  }

  Future<SubscriptionPaymentOrder> createOrder() async {
    final response = await ApiClient.post(ApiConstants.createSubscriptionOrder);
    return SubscriptionPaymentOrder.fromJson(response as Map<String, dynamic>);
  }

  Future<SubscriptionPaymentStatus> getPaymentStatus(String orderId) async {
    final response = await ApiClient.get(ApiConstants.subscriptionPaymentStatus(orderId));
    final result = SubscriptionPaymentStatus.fromJson(response as Map<String, dynamic>);
    await ApiClient.saveCachedSubscription(result.subscription.toJson());
    return result;
  }
}
