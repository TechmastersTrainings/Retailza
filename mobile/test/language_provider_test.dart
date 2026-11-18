import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retailza/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageProvider Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to Kannada language mode', () {
      final provider = LanguageProvider();
      expect(provider.languageMode, equals(LanguageMode.kannada));
      expect(provider.isKannada, isTrue);
      expect(provider.isHindi, isFalse);
      expect(provider.currentCode, equals('kn'));
      expect(provider.activeLanguageName, equals('ಕನ್ನಡ'));
      expect(provider.targetSwitchName, equals('हिंदी'));
    });

    test('Formats dual bilingual strings correctly in Kannada mode by default', () {
      final provider = LanguageProvider();
      final dualString = provider.t("Add Product", kn: "ಹೊಸ ವಸ್ತು", hi: "नया सामान");
      expect(dualString, equals("Add Product (ಹೊಸ ವಸ್ತು)"));
    });

    test('Toggles to Hindi mode and back to Kannada mode', () async {
      final provider = LanguageProvider();
      expect(provider.isKannada, isTrue);

      await provider.toggleLanguage();
      expect(provider.isKannada, isFalse);
      expect(provider.isHindi, isTrue);
      expect(provider.currentCode, equals('hi'));
      expect(provider.activeLanguageName, equals('हिंदी'));
      expect(provider.targetSwitchName, equals('ಕನ್ನಡ'));

      final hindiDual = provider.t("Add Product", kn: "ಹೊಸ ವಸ್ತು", hi: "नया सामान");
      expect(hindiDual, equals("Add Product (नया सामान)"));

      await provider.toggleLanguage();
      expect(provider.isKannada, isTrue);
      expect(provider.isHindi, isFalse);
    });

    test('Set explicit language mode', () async {
      final provider = LanguageProvider();
      await provider.setLanguage(LanguageMode.hindi);
      expect(provider.isHindi, isTrue);

      await provider.setLanguage(LanguageMode.kannada);
      expect(provider.isKannada, isTrue);
    });

    test('Returns correct standard UI getters', () {
      final provider = LanguageProvider();
      expect(provider.cashTitle, contains("Cash"));
      expect(provider.cashTitle, contains("ನಗದು"));
      expect(provider.upiTitle, contains("UPI"));
      expect(provider.upiTitle, contains("ಆನ್‌ಲೈನ್"));
      expect(provider.khataTitle, contains("Khata"));
      expect(provider.khataTitle, contains("ಉದ್ದರಿ"));
    });
  });
}
