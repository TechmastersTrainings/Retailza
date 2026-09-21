import 'package:flutter_test/flutter_test.dart';
import 'package:retailza/core/constants/legal_content.dart';

void main() {
  group('Legal Content & Compliance Tests', () {
    test('Company and brand identity are properly mapped', () {
      expect(LegalContent.brandName, equals('Retailza'));
      expect(LegalContent.companyName, equals('TechMasters Innovations Private Limited'));
      expect(LegalContent.privacyEmail, contains('@retailza.com'));
      expect(LegalContent.supportEmail, contains('@retailza.com'));
      expect(LegalContent.copyrightNotice, contains('TechMasters Innovations Private Limited'));
      expect(LegalContent.copyrightNotice, contains('2026'));
    });

    test('Privacy Policy contains required sections and customer info clauses', () {
      expect(LegalContent.privacyPolicySections.isNotEmpty, isTrue);
      
      final titles = LegalContent.privacyPolicySections.map((s) => s.title).toList();
      expect(titles.any((t) => t.contains('Information We Collect')), isTrue);
      expect(titles.any((t) => t.contains('How We Use Your Information')), isTrue);
      expect(titles.any((t) => t.contains('Customer Information')), isTrue);
      expect(titles.any((t) => t.contains('Payment Information')), isTrue);
      expect(titles.any((t) => t.contains('Data Security')), isTrue);
      expect(titles.any((t) => t.contains('Data Sharing')), isTrue);
      expect(titles.any((t) => t.contains('Data Retention')), isTrue);
      expect(titles.any((t) => t.contains('Account Deletion')), isTrue);
      expect(titles.any((t) => t.contains('Account Security')), isTrue);
    });

    test('Terms & Conditions contains required commercial clauses', () {
      expect(LegalContent.termsConditionsSections.isNotEmpty, isTrue);
      
      final titles = LegalContent.termsConditionsSections.map((s) => s.title).toList();
      expect(titles.any((t) => t.contains('Acceptance')), isTrue);
      expect(titles.any((t) => t.contains('Description of Services')), isTrue);
      expect(titles.any((t) => t.contains('Merchant Accounts')), isTrue);
      expect(titles.any((t) => t.contains('Customer Data')), isTrue);
      expect(titles.any((t) => t.contains('Subscriptions')), isTrue);
      expect(titles.any((t) => t.contains('Counter UPI Payments')), isTrue);
      expect(titles.any((t) => t.contains('Intellectual Property')), isTrue);
      expect(titles.any((t) => t.contains('Limitation of Liability')), isTrue);
    });
  });
}
