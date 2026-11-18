import 'package:flutter_test/flutter_test.dart';
import 'package:retailza/core/constants/api_constants.dart';
import 'package:retailza/services/subscription_service.dart';

void main() {
  group('Direct-UPI subscription payment models', () {
    test('order parses the collecting UPI details', () {
      final order = SubscriptionPaymentOrder.fromJson({
        'order_id': 'RTZ7AB12CD34EF56',
        'amount': '49.00',
        'currency': 'INR',
        'subscription_id': 7,
        'upi_id': 'retailza@okhdfcbank',
        'payee_name': 'Retailza',
        'upi_intent': 'upi://pay?pa=retailza@okhdfcbank&am=49.00&tr=RTZ7AB12CD34EF56',
        'note': 'Retailza 30 day plan',
      });

      expect(order.orderId, 'RTZ7AB12CD34EF56');
      expect(order.amount, 49.0);
      expect(order.upiId, 'retailza@okhdfcbank');
      expect(order.payeeName, 'Retailza');
      expect(order.upiIntent, startsWith('upi://pay'));
      expect(order.note, 'Retailza 30 day plan');
    });

    test('status maps success, review and failed states', () {
      Map<String, dynamic> sub(bool active) => {
            'id': 1,
            'shop_id': 2,
            'plan_name': 'basic',
            'amount': '49.00',
            'status': active ? 'ACTIVE' : 'PENDING',
            'is_active': active,
          };

      final paid = SubscriptionPaymentStatus.fromJson(
          {'order_id': 'RTZ1', 'status': 'SUCCESS', 'subscription': sub(true)});
      expect(paid.isPaid, isTrue);
      expect(paid.subscription.isActive, isTrue);

      final review = SubscriptionPaymentStatus.fromJson(
          {'order_id': 'RTZ1', 'status': 'REVIEW', 'subscription': sub(false)});
      expect(review.isUnderReview, isTrue);
      expect(review.isPaid, isFalse);

      final pending = SubscriptionPaymentStatus.fromJson(
          {'order_id': 'RTZ1', 'status': 'PENDING', 'subscription': sub(false)});
      expect(pending.isPaid, isFalse);
      expect(pending.isFinalFailure, isFalse);

      final failed = SubscriptionPaymentStatus.fromJson({
        'order_id': 'RTZ1',
        'status': 'FAILED',
        'message': 'Payment could not be verified.',
        'subscription': sub(false),
      });
      expect(failed.isFinalFailure, isTrue);
      expect(failed.message, isNotNull);
    });

    test('submit-utr endpoint encodes the order id', () {
      expect(ApiConstants.submitSubscriptionUtr('RTZ1'),
          '/subscriptions/payments/RTZ1/submit-utr');
      expect(ApiConstants.submitSubscriptionUtr('a/b?c'),
          '/subscriptions/payments/a%2Fb%3Fc/submit-utr');
    });

    test('status endpoint encodes the order id', () {
      expect(ApiConstants.subscriptionPaymentStatus('RTZ1'),
          '/subscriptions/payments/RTZ1/status');
      expect(ApiConstants.subscriptionPaymentStatus('a/b?c'),
          '/subscriptions/payments/a%2Fb%3Fc/status');
    });
  });
}
