import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:retailza/widgets/upi_qr_helper.dart';

void main() {
  group('UPI & QR Helper Unit Tests', () {
    test('decodeBase64Image parses raw base64 and data URI', () {
      const sampleText = "RetailzaUPI";
      final encoded = base64Encode(utf8.encode(sampleText));
      
      // Test raw base64
      final rawBytes = UpiQrHelper.decodeBase64Image(encoded);
      expect(rawBytes, isNotNull);
      expect(utf8.decode(rawBytes!), sampleText);

      // Test data URI format
      final dataUri = "data:image/png;base64,$encoded";
      final uriBytes = UpiQrHelper.decodeBase64Image(dataUri);
      expect(uriBytes, isNotNull);
      expect(utf8.decode(uriBytes!), sampleText);

      // Test null and invalid inputs
      expect(UpiQrHelper.decodeBase64Image(null), isNull);
      expect(UpiQrHelper.decodeBase64Image(''), isNull);
      expect(UpiQrHelper.decodeBase64Image('   '), isNull);
    });

    test('UPI Payment URI formatting adheres to NPCI standards', () {
      const upiId = 'retailza@icici';
      const payeeName = 'Sri Ganesh Stores';
      const amount = 345.50;
      const transactionNote = 'Bill #108';

      final encodedPayee = Uri.encodeComponent(payeeName);
      final encodedNote = Uri.encodeComponent(transactionNote);
      final upiUri = 'upi://pay?pa=$upiId&pn=$encodedPayee&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$encodedNote';

      expect(upiUri, startsWith('upi://pay?'));
      expect(upiUri, contains('pa=retailza@icici'));
      expect(upiUri, contains('am=345.50'));
      expect(upiUri, contains('cu=INR'));
      expect(upiUri, contains('tn=Bill%20%23108'));
    });
  });
}
