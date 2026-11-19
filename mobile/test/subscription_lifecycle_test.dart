import 'package:flutter_test/flutter_test.dart';
import 'package:retailza/models/subscription_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription Lifecycle & Auto-lock Tests', () {
    test('Day 1 to 14: Active trial, full features unlocked, reminder false', () {
      final now = DateTime.now();
      final sub = SubscriptionModel(
        id: 1,
        shopId: 1,
        planName: 'trial',
        amount: 49.0,
        status: 'ACTIVE',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 25)),
        isActive: true,
        trialDaysCompleted: false,
        daysRemaining: 25,
        daysElapsed: 5,
        isLocked: false,
      );

      expect(sub.isTrial, isTrue);
      expect(sub.computedIsLocked, isFalse);
      expect(sub.shouldShow14DayReminder, isFalse);
    });

    test('Day 15 to 29: 14-day trial completed, reminder true, app not locked yet', () {
      final now = DateTime.now();
      final sub = SubscriptionModel(
        id: 1,
        shopId: 1,
        planName: 'trial',
        amount: 49.0,
        status: 'ACTIVE',
        startDate: now.subtract(const Duration(days: 16)),
        endDate: now.add(const Duration(days: 14)),
        isActive: true,
        trialDaysCompleted: true,
        daysRemaining: 14,
        daysElapsed: 16,
        isLocked: false,
      );

      expect(sub.isTrial, isTrue);
      expect(sub.trialDaysCompleted, isTrue);
      expect(sub.computedIsLocked, isFalse);
      expect(sub.shouldShow14DayReminder, isTrue);
    });

    test('Day 30+: Evaluation period ended, auto-lock is triggered', () {
      final now = DateTime.now();
      final sub = SubscriptionModel(
        id: 1,
        shopId: 1,
        planName: 'trial',
        amount: 49.0,
        status: 'EXPIRED',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(hours: 1)),
        isActive: false,
        trialDaysCompleted: true,
        daysRemaining: 0,
        daysElapsed: 30,
        isLocked: true,
        lockReason: 'Your 30-day evaluation period has completed.',
      );

      expect(sub.computedIsLocked, isTrue);
      expect(sub.shouldShow14DayReminder, isFalse);
    });

    test('Payment made (₹49): App unlocks immediately into active Basic plan', () {
      final now = DateTime.now();
      final sub = SubscriptionModel(
        id: 1,
        shopId: 1,
        planName: 'basic',
        amount: 49.0,
        status: 'ACTIVE',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        isActive: true,
        trialDaysCompleted: false,
        daysRemaining: 30,
        daysElapsed: 0,
        isLocked: false,
      );

      expect(sub.isTrial, isFalse);
      expect(sub.computedIsLocked, isFalse);
      expect(sub.shouldShow14DayReminder, isFalse);
      expect(sub.daysRemaining, equals(30));
    });
  });
}

