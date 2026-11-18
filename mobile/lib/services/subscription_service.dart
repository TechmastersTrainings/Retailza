import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/subscription_model.dart';

/// A direct-UPI payment order: the shop owner pays ₹49 into Retailza's own
/// UPI ID with any UPI app, then submits the UTR from the receipt.
class SubscriptionPaymentOrder {
  final String orderId;
  final double amount;
  final String upiId; // the collecting VPA, e.g. techmasters@okhdfcbank
  final String payeeName;
  final String upiIntent; // upi://pay?... scannable / tappable
  final String note;

  SubscriptionPaymentOrder({
    required this.orderId,
    required this.amount,
    required this.upiId,
    required this.payeeName,
    required this.upiIntent,
    required this.note,
  });

  factory SubscriptionPaymentOrder.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentOrder(
      orderId: json['order_id'] as String,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      upiId: json['upi_id'] as String? ?? '',
      payeeName: json['payee_name'] as String? ?? 'Retailza',
      upiIntent: json['upi_intent'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

/// Server-verified payment status. The backend activates the subscription only
/// after a valid, unused UTR is submitted; the app never decides a payment paid.
class SubscriptionPaymentStatus {
  /// PENDING, REVIEW, SUCCESS or FAILED
  final String status;
  final String? message;
  final SubscriptionModel subscription;

  SubscriptionPaymentStatus({required this.status, this.message, required this.subscription});

  bool get isPaid => status == 'SUCCESS';
  bool get isUnderReview => status == 'REVIEW';
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

  /// Submits the 12-digit UTR from the payment receipt to confirm the payment.
  Future<SubscriptionPaymentStatus> submitUtr(String orderId, String utr) async {
    final response = await ApiClient.post(
      ApiConstants.submitSubscriptionUtr(orderId),
      body: {'utr': utr},
    );
    final result = SubscriptionPaymentStatus.fromJson(response as Map<String, dynamic>);
    await ApiClient.saveCachedSubscription(result.subscription.toJson());
    return result;
  }

  Future<SubscriptionPaymentStatus> getPaymentStatus(String orderId) async {
    final response = await ApiClient.get(ApiConstants.subscriptionPaymentStatus(orderId));
    final result = SubscriptionPaymentStatus.fromJson(response as Map<String, dynamic>);
    await ApiClient.saveCachedSubscription(result.subscription.toJson());
    return result;
  }
}
