import 'package:flutter_test/flutter_test.dart';
import 'package:retailza/core/constants/api_constants.dart';
import 'package:retailza/services/subscription_service.dart';

void main() {
  group('UPI Gateway subscription payment models', () {
    test('order parses gateway payment details', () {
      final order = SubscriptionPaymentOrder.fromJson({
        'order_id': 'ORDAB12CD34EF56GH78',
        'amount': '49.00',
        'currency': 'INR',
        'subscription_id': 7,
        'payment_url': 'https://pay.example.com/pay/ORDAB12CD34EF56GH78',
        'upi_intent': 'upi://pay?pa=retailza@upi&am=49.00&tr=ORDAB12CD34EF56GH78',
        'expires_at': '2026-11-18T12:15:00+05:30',
        'test': false,
      });

      expect(order.orderId, 'ORDAB12CD34EF56GH78');
      expect(order.amount, 49.0);
      expect(order.upiIntent, startsWith('upi://pay'));
      expect(order.expiresAt, isNotNull);
      expect(order.isTest, isFalse);
    });

    test('hosted PG orders have no UPI intent', () {
      final order = SubscriptionPaymentOrder.fromJson({
        'order_id': 'ORD1',
        'amount': 49,
        'payment_url': 'https://pay.example.com/pay/ORD1',
        'upi_intent': null,
      });
      expect(order.upiIntent, isNull);
      expect(order.paymentUrl, 'https://pay.example.com/pay/ORD1');
    });

    test('status maps paid and failed states', () {
      Map<String, dynamic> sub(bool active) => {
            'id': 1,
            'shop_id': 2,
            'plan_name': 'basic',
            'amount': '49.00',
            'status': active ? 'ACTIVE' : 'PENDING',
            'is_active': active,
          };

      final paid = SubscriptionPaymentStatus.fromJson({'order_id': 'ORD1', 'status': 'SUCCESS', 'subscription': sub(true)});
      expect(paid.isPaid, isTrue);
      expect(paid.subscription.isActive, isTrue);

      final pending = SubscriptionPaymentStatus.fromJson({'order_id': 'ORD1', 'status': 'PENDING', 'subscription': sub(false)});
      expect(pending.isPaid, isFalse);
      expect(pending.isFinalFailure, isFalse);

      final failed = SubscriptionPaymentStatus.fromJson({
        'order_id': 'ORD1',
        'status': 'FAILED',
        'message': 'Payment could not be verified.',
        'subscription': sub(false),
      });
      expect(failed.isFinalFailure, isTrue);
      expect(failed.message, isNotNull);
    });

    test('status endpoint encodes the order id', () {
      expect(ApiConstants.subscriptionPaymentStatus('ORD1'), '/subscriptions/payments/ORD1/status');
      expect(ApiConstants.subscriptionPaymentStatus('a/b?c'), '/subscriptions/payments/a%2Fb%3Fc/status');
    });
  });
}
