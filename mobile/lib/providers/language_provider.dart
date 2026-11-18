import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LanguageMode {
  kannada, // English (Kannada) - DEFAULT
  hindi,   // English (Hindi)
}

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = "retailza_app_language_mode";
  LanguageMode _languageMode = LanguageMode.kannada; // Kannada by default

  LanguageProvider() {
    _loadSavedLanguage();
  }

  LanguageMode get languageMode => _languageMode;
  bool get isKannada => _languageMode == LanguageMode.kannada;
  bool get isHindi => _languageMode == LanguageMode.hindi;

  String get currentCode => isKannada ? "kn" : "hi";
  String get activeLanguageName => isKannada ? "ಕನ್ನಡ" : "हिंदी";
  String get currentDisplayName => isKannada ? "English (ಕನ್ನಡ)" : "English (हिंदी)";
  String get targetSwitchName => isKannada ? "हिंदी" : "ಕನ್ನಡ";

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == "hindi") {
        _languageMode = LanguageMode.hindi;
      } else {
        _languageMode = LanguageMode.kannada; // Default is Kannada
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(LanguageMode mode) async {
    if (_languageMode == mode) return;
    _languageMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode == LanguageMode.hindi ? "hindi" : "kannada");
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final next = isKannada ? LanguageMode.hindi : LanguageMode.kannada;
    await setLanguage(next);
  }

  /// Format dual bilingual string: e.g. "Add Product (ಹೊಸ ವಸ್ತು)" or "Add Product (नया सामान)"
  String t(String english, {required String kn, required String hi}) {
    final translation = isKannada ? kn : hi;
    return "$english ($translation)";
  }

  /// Pure translated string without English prefix
  String raw({required String kn, required String hi}) {
    return isKannada ? kn : hi;
  }

  // --- Common UI Term Getters for Clean Screen Code ---
  String get addProductTitle => t("Add New Product", kn: "ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ", hi: "नया सामान");
  String get bulkUploadTitle => t("Bulk Product Upload", kn: "ಸಗಟು ವಸ್ತುಗಳು", hi: "थोक सामान");
  String get chooseFileLabel => t("Choose File", kn: "ಫೈಲ್ ಆಯ್ಕೆಮಾಡಿ", hi: "फ़ाइल चुनें");
  String get browseFromPhone => t("Browse from Phone", kn: "ಫೋನ್‌ನಿಂದ ಆಯ್ಕೆಮಾಡಿ", hi: "फ़ोन से चुनें");
  String get readyMadeCatalog => t("1-Tap Load Ready Catalog", kn: "ರೆಡಿಮೇಡ್ ಲಿಸ್ಟ್ ಲೋಡ್ ಮಾಡಿ", hi: "रेडीमेड लिस्ट लोड करें");
  String get productNameLabel => t("Product Name", kn: "ವಸ್ತುವಿನ ಹೆಸರು", hi: "सामान का नाम");
  String get categoryLabel => t("Category", kn: "ವರ್ಗ", hi: "श्रेणी");
  String get unitLabel => t("Unit", kn: "ಪ್ರಮಾಣ", hi: "इकाई");
  String get sellingPriceLabel => t("Selling Price", kn: "ಮಾರಾಟ ಬೆಲೆ", hi: "बिक्री मूल्य");
  String get purchasePriceLabel => t("Purchase Cost", kn: "ಖರೀದಿ ಬೆಲೆ", hi: "खरीद मूल्य");
  String get stockLabel => t("Stock Quantity", kn: "ದಾಸ್ತಾನು", hi: "स्टॉक");
  String get lowStockLabel => t("Low Stock Alert", kn: "ಕಡಿಮೆ ದಾಸ್ತಾನು ಎಚ್ಚರಿಕೆ", hi: "कम स्टॉक अलर्ट");
  String get saveProductButton => t("Save Product", kn: "ವಸ್ತು ಉಳಿಸಿ", hi: "सामान सुरक्षित करें");
  String get shopNameLabel => t("Shop Name", kn: "ಅಂಗಡಿಯ ಹೆಸರು", hi: "दुकान का नाम");
  String get ownerNameLabel => t("Owner Name", kn: "ಮಾಲೀಕರ ಹೆಸರು", hi: "दुकानदार का नाम");
  String get storeAddressLabel => t("Store Address", kn: "ವಿಳಾಸ", hi: "पता");
  String get cityLabel => t("City", kn: "ನಗರ", hi: "शहर");
  String get stateLabel => t("State", kn: "ರಾಜ್ಯ", hi: "राज्य");
  String get pincodeLabel => t("Pincode", kn: "ಪಿನ್‌ಕೋಡ್", hi: "पिनकोड");
  String get saveAndContinue => t("Save & Continue", kn: "ಮುಂದುವರಿಯಿರಿ", hi: "आगे बढ़ें");
  String get cashTitle => t("Cash", kn: "ನಗದು", hi: "नकद");
  String get upiTitle => t("UPI", kn: "ಆನ್‌ಲೈನ್", hi: "ऑनलाइन");
  String get khataTitle => t("Khata", kn: "ಉದ್ದರಿ", hi: "उधार");
  String get dueLabel => t("Due", kn: "ಬಾಕಿ", hi: "बाकी");
  String get settledLabel => t("Settled", kn: "ಪಾವತಿಸಲಾಗಿದೆ", hi: "चुका दिया");
  String get discountLabel => t("Discount", kn: "ರಿಯಾಯಿತಿ", hi: "छूट");
  String get finalAmountLabel => t("Final Amount", kn: "ಒಟ್ಟು ಪಾವತಿ", hi: "कुल देय");
  String get shareWhatsApp => t("Share on WhatsApp", kn: "ರಶೀದಿ ಕಳುಹಿಸಿ", hi: "रसीद भेजें");
  String get startNextBill => t("Start Next Bill", kn: "ಮುಂದಿನ ಬಿಲ್", hi: "अगला बिल");
  String get storeUpiScanner => t("Store UPI Scanner", kn: "QR ಕೋಡ್", hi: "QR कोड");
  String get saveQrDetails => t("Save QR Details", kn: "ವಿವರಗಳನ್ನು ಉಳಿಸಿ", hi: "सुरक्षित करें");
  String get galleryLabel => t("Gallery", kn: "ಗ್ಯಾಲರಿ", hi: "गैलरी");
  String get cameraLabel => t("Camera", kn: "ಕ್ಯಾಮೆರಾ", hi: "कैमरा");
  String get sampleQrLabel => t("Use Sample Test QR", kn: "ಮಾದರಿ ಕ್ಯೂಆರ್", hi: "सैंपल क्यूआर");
  String get settingsTitle => t("Settings & Store", kn: "ಸೆಟ್ಟಿಂಗ್‌ಗಳು", hi: "सेटिंग्स");
  String get logoutLabel => t("Logout", kn: "ಲಾಗ್ ಔಟ್", hi: "लॉग आउट");
  String get deleteAccountLabel => t("Delete Account", kn: "ಖಾತೆ ಅಳಿಸಿ", hi: "खाता हटाएं");
}

