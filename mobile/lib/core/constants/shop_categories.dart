import 'package:flutter/material.dart';

class CatalogProductPreset {
  final String name;
  final String? englishName;
  final String? kannadaName;
  final String? hindiName;
  final String defaultUnit;
  final String defaultCategory;
  final double defaultPurchasePrice;
  final double defaultSellingPrice;
  final double defaultStock;

  const CatalogProductPreset({
    required this.name,
    this.englishName,
    this.kannadaName,
    this.hindiName,
    required this.defaultUnit,
    required this.defaultCategory,
    this.defaultPurchasePrice = 0.0,
    this.defaultSellingPrice = 0.0,
    this.defaultStock = 10.0,
  });

  String getLocalizedName(bool isKannada) {
    if (englishName != null && kannadaName != null && hindiName != null) {
      return "$englishName (${isKannada ? kannadaName : hindiName})";
    }
    return name;
  }
}

class ShopCategoryInfo {
  final String id;
  final String englishName;
  final String hindiName;
  final String kannadaName;
  final IconData icon;
  final Color themeColor;
  final List<String> productCategories;
  final List<CatalogProductPreset> catalogPresets;

  const ShopCategoryInfo({
    required this.id,
    required this.englishName,
    required this.hindiName,
    required this.kannadaName,
    required this.icon,
    required this.themeColor,
    required this.productCategories,
    required this.catalogPresets,
  });

  String getLocalizedName(bool isKannada) => isKannada ? kannadaName : hindiName;
  String getDisplayName(bool isKannada) => "$englishName (${getLocalizedName(isKannada)})";
  String get displayName => "$englishName ($kannadaName)";
}

class ShopCategories {
  static const String provisionStore = "Provision Store";
  static const String electrical = "Electrical";
  static const String riceRetail = "Rice & Grain Retail";
  static const String furniture = "Furniture";
  static const String clothing = "Clothing & Garments";
  static const String hardware = "Hardware & Sanitary";
  static const String pharmacy = "Medical & Pharmacy";
  static const String generalStore = "General Store";

  static const List<ShopCategoryInfo> categories = [
    ShopCategoryInfo(
      id: provisionStore,
      englishName: "Provision Store",
      kannadaName: "ಕಿರಾಣಿ ಮತ್ತು ಪ್ರಾವಿಷನ್ ಸ್ಟೋರ್",
      hindiName: "किराना व प्रोविजन स्टोर",
      icon: Icons.local_grocery_store_rounded,
      themeColor: Color(0xFF1B5E20),
      productCategories: [
        "Groceries",
        "Grains & Pulses",
        "Cooking Oil",
        "Spices & Masala",
        "Dairy & Bakery",
        "Beverages",
        "Snacks",
        "Personal Care",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "Rice (ಅಕ್ಕಿ)", englishName: "Rice", kannadaName: "ಅಕ್ಕಿ", hindiName: "चावल", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 42.0, defaultSellingPrice: 55.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Wheat / Atta (ಗೋಧಿ ಹಿಟ್ಟು)", englishName: "Wheat / Atta", kannadaName: "ಗೋಧಿ ಹಿಟ್ಟು", hindiName: "गेहूं का आटा", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 34.0, defaultSellingPrice: 42.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Sugar (ಸಕ್ಕರೆ)", englishName: "Sugar", kannadaName: "ಸಕ್ಕರೆ", hindiName: "चीनी / शक्कर", defaultUnit: "kg", defaultCategory: "Groceries", defaultPurchasePrice: 38.0, defaultSellingPrice: 44.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Salt / Tata Salt (ಉಪ್ಪು)", englishName: "Salt / Tata Salt", kannadaName: "ಉಪ್ಪು", hindiName: "नमक", defaultUnit: "packet", defaultCategory: "Groceries", defaultPurchasePrice: 22.0, defaultSellingPrice: 28.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Tea Leaves / Chai Patti (ಟೀ ಪುಡಿ)", englishName: "Tea Leaves / Chai Patti", kannadaName: "ಟೀ ಪುಡಿ", hindiName: "चाय पत्ती", defaultUnit: "packet", defaultCategory: "Beverages", defaultPurchasePrice: 110.0, defaultSellingPrice: 140.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Toor Dal / Arhar Dal (ತೊಗರಿ ಬೇಳೆ)", englishName: "Toor Dal / Arhar Dal", kannadaName: "ತೊಗರಿ ಬೇಳೆ", hindiName: "तूर दाल", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 135.0, defaultSellingPrice: 160.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Moong Dal (ಹೆಸರು ಬೇಳೆ)", englishName: "Moong Dal", kannadaName: "ಹೆಸರು ಬೇಳೆ", hindiName: "मूंग दाल", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 100.0, defaultSellingPrice: 120.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Chana Dal (ಕಡಲೆ ಬೇಳೆ)", englishName: "Chana Dal", kannadaName: "ಕಡಲೆ ಬೇಳೆ", hindiName: "चना दाल", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 75.0, defaultSellingPrice: 90.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Mustard Oil / Sarson Tel (ಸಾಸಿವೆ ಎಣ್ಣೆ 1L)", englishName: "Mustard Oil / Sarson Tel", kannadaName: "ಸಾಸಿವೆ ಎಣ್ಣೆ 1L", hindiName: "सरसों तेल 1L", defaultUnit: "l", defaultCategory: "Cooking Oil", defaultPurchasePrice: 125.0, defaultSellingPrice: 150.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Sunflower Refined Oil (ಸೂರ್ಯಕಾಂತಿ ಎಣ್ಣೆ 1L)", englishName: "Sunflower Refined Oil", kannadaName: "ಸೂರ್ಯಕಾಂತಿ ಎಣ್ಣೆ 1L", hindiName: "रिफाइंड तेल 1L", defaultUnit: "l", defaultCategory: "Cooking Oil", defaultPurchasePrice: 115.0, defaultSellingPrice: 135.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Turmeric Powder / Haldi (ಅರಿಶಿನ ಪುಡಿ)", englishName: "Turmeric Powder / Haldi", kannadaName: "ಅರಿಶಿನ ಪುಡಿ", hindiName: "हल्दी", defaultUnit: "packet", defaultCategory: "Spices & Masala", defaultPurchasePrice: 26.0, defaultSellingPrice: 35.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Red Chilli Powder / Mirch (ಖಾರದ ಪುಡಿ)", englishName: "Red Chilli Powder / Mirch", kannadaName: "ಖಾರದ ಪುಡಿ", hindiName: "लाल मिर्च", defaultUnit: "packet", defaultCategory: "Spices & Masala", defaultPurchasePrice: 35.0, defaultSellingPrice: 45.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Coriander Powder / Dhaniya (ಧನಿಯಾ ಪುಡಿ)", englishName: "Coriander Powder / Dhaniya", kannadaName: "ಧನಿಯಾ ಪುಡಿ", hindiName: "धनिया", defaultUnit: "packet", defaultCategory: "Spices & Masala", defaultPurchasePrice: 30.0, defaultSellingPrice: 40.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Besan / Gram Flour (ಕಡಲೆ ಹಿಟ್ಟು 1kg)", englishName: "Besan / Gram Flour", kannadaName: "ಕಡಲೆ ಹಿಟ್ಟು 1kg", hindiName: "बेसन 1kg", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 70.0, defaultSellingPrice: 85.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Maida (ಮೈದಾ ಹಿಟ್ಟು)", englishName: "Maida", kannadaName: "ಮೈದಾ ಹಿಟ್ಟು", hindiName: "मैदा", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 32.0, defaultSellingPrice: 40.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Suji / Rava (ರವೆ)", englishName: "Suji / Rava", kannadaName: "ರವೆ", hindiName: "सूजी", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 35.0, defaultSellingPrice: 45.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Biscuits / Cookies (ಬಿಸ್ಕತ್ತು)", englishName: "Biscuits / Cookies", kannadaName: "ಬಿಸ್ಕತ್ತು", hindiName: "बिस्कुट", defaultUnit: "packet", defaultCategory: "Snacks", defaultPurchasePrice: 8.0, defaultSellingPrice: 10.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Bathing Soap (ಸ್ನಾನದ ಸೋಪು)", englishName: "Bathing Soap", kannadaName: "ಸ್ನಾನದ ಸೋಪು", hindiName: "साबुन", defaultUnit: "piece", defaultCategory: "Personal Care", defaultPurchasePrice: 28.0, defaultSellingPrice: 35.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Detergent Powder 1kg (ಡಿಟರ್ಜೆಂಟ್ ಪೌಡರ್)", englishName: "Detergent Powder 1kg", kannadaName: "ಡಿಟರ್ಜೆಂಟ್ ಪೌಡರ್", hindiName: "डिटर्जेंट", defaultUnit: "packet", defaultCategory: "Groceries", defaultPurchasePrice: 52.0, defaultSellingPrice: 65.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Toothpaste 100g (ಟೂತ್‌ಪೇಸ್ಟ್)", englishName: "Toothpaste 100g", kannadaName: "ಟೂತ್‌ಪೇಸ್ಟ್", hindiName: "टूथपेस्ट", defaultUnit: "piece", defaultCategory: "Personal Care", defaultPurchasePrice: 48.0, defaultSellingPrice: 60.0, defaultStock: 25.0),
      ],
    ),
    ShopCategoryInfo(
      id: electrical,
      englishName: "Electrical",
      kannadaName: "ಎಲೆಕ್ಟ್ರಿಕಲ್ ಸ್ಟೋರ್",
      hindiName: "इलेक्ट्रिकल स्टोर",
      icon: Icons.electrical_services_rounded,
      themeColor: Color(0xFFE65100),
      productCategories: [
        "Switches & Boards",
        "Wires & Cables",
        "Lighting",
        "Fans & Appliances",
        "Accessories & Tools",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "Modular Switch 6A (ಸ್ವಿಚ್ 6A)", englishName: "Modular Switch 6A", kannadaName: "ಸ್ವಿಚ್ 6A", hindiName: "स्विच 6A", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 30.0, defaultSellingPrice: 45.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Modular Switch 16A Power (ಪವರ್ ಸ್ವಿಚ್ 16A)", englishName: "Modular Switch 16A Power", kannadaName: "ಪವರ್ ಸ್ವಿಚ್ 16A", hindiName: "पावर स्विच 16A", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 65.0, defaultSellingPrice: 95.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Switch Board 4+1 (ಸ್ವಿಚ್ ಬೋರ್ಡ್ 4+1)", englishName: "Switch Board 4+1", kannadaName: "ಸ್ವಿಚ್ ಬೋರ್ಡ್ 4+1", hindiName: "स्विच बोर्ड 4+1", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 120.0, defaultSellingPrice: 180.0, defaultStock: 15.0),
        CatalogProductPreset(name: "Switch Board 8+2 (ಸ್ವಿಚ್ ಬೋರ್ಡ್ 8+2)", englishName: "Switch Board 8+2", kannadaName: "ಸ್ವಿಚ್ ಬೋರ್ಡ್ 8+2", hindiName: "स्विच बोर्ड 8+2", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 220.0, defaultSellingPrice: 320.0, defaultStock: 12.0),
        CatalogProductPreset(name: "Bell Push Button (ಬೆಲ್ ಬಟನ್)", englishName: "Bell Push Button", kannadaName: "ಬೆಲ್ ಬಟನ್", hindiName: "डोर बेल बटन", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 38.0, defaultSellingPrice: 60.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Copper Wire 1.0 sq mm (ಕಾಪರ್ ವೈರ್ 1.0mm)", englishName: "Copper Wire 1.0 sq mm", kannadaName: "ಕಾಪರ್ ವೈರ್ 1.0mm", hindiName: "कॉपर वायर 1.0mm", defaultUnit: "meter", defaultCategory: "Wires & Cables", defaultPurchasePrice: 13.0, defaultSellingPrice: 18.0, defaultStock: 180.0),
        CatalogProductPreset(name: "Copper Wire 1.5 sq mm (ಕಾಪರ್ ವೈರ್ 1.5mm)", englishName: "Copper Wire 1.5 sq mm", kannadaName: "ಕಾಪರ್ ವೈರ್ 1.5mm", hindiName: "कॉपर वायर 1.5mm", defaultUnit: "meter", defaultCategory: "Wires & Cables", defaultPurchasePrice: 19.0, defaultSellingPrice: 26.0, defaultStock: 180.0),
        CatalogProductPreset(name: "Copper Wire 2.5 sq mm (ಕಾಪರ್ ವೈರ್ 2.5mm)", englishName: "Copper Wire 2.5 sq mm", kannadaName: "ಕಾಪರ್ ವೈರ್ 2.5mm", hindiName: "कॉपर वायर 2.5mm", defaultUnit: "meter", defaultCategory: "Wires & Cables", defaultPurchasePrice: 31.0, defaultSellingPrice: 42.0, defaultStock: 90.0),
        CatalogProductPreset(name: "Flexible Wire Coil 90m (ವೈರ್ ಬಂಡಲ್)", englishName: "Flexible Wire Coil 90m", kannadaName: "ವೈರ್ ಬಂಡಲ್", hindiName: "वायर बंडल", defaultUnit: "packet", defaultCategory: "Wires & Cables", defaultPurchasePrice: 680.0, defaultSellingPrice: 850.0, defaultStock: 8.0),
        CatalogProductPreset(name: "MCB Single Pole 16A (ಸಿಂಗಲ್ ಪೋಲ್ MCB)", englishName: "MCB Single Pole 16A", kannadaName: "ಸಿಂಗಲ್ ಪೋಲ್ MCB", hindiName: "सिंगल पोल एमसीबी", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 110.0, defaultSellingPrice: 160.0, defaultStock: 20.0),
        CatalogProductPreset(name: "MCB Double Pole 32A (ಡಬಲ್ ಪೋಲ್ MCB)", englishName: "MCB Double Pole 32A", kannadaName: "ಡಬಲ್ ಪೋಲ್ MCB", hindiName: "डीपी एमसीबी", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 270.0, defaultSellingPrice: 380.0, defaultStock: 10.0),
        CatalogProductPreset(name: "LED Bulb 9W (ಎಲ್‌ಇಡಿ ಬಲ್ಬ್ 9W)", englishName: "LED Bulb 9W", kannadaName: "ಎಲ್‌ಇಡಿ ಬಲ್ಬ್ 9W", hindiName: "एलईडी बल्ब 9W", defaultUnit: "piece", defaultCategory: "Lighting", defaultPurchasePrice: 60.0, defaultSellingPrice: 90.0, defaultStock: 40.0),
        CatalogProductPreset(name: "LED Bulb 12W (ಎಲ್‌ಇಡಿ ಬಲ್ಬ್ 12W)", englishName: "LED Bulb 12W", kannadaName: "ಎಲ್‌ಇಡಿ ಬಲ್ಬ್ 12W", hindiName: "एलईडी बल्ब 12W", defaultUnit: "piece", defaultCategory: "Lighting", defaultPurchasePrice: 90.0, defaultSellingPrice: 130.0, defaultStock: 30.0),
        CatalogProductPreset(name: "LED Tube Light 20W (ಟ್ಯೂಬ್ ಲೈಟ್ 20W)", englishName: "LED Tube Light 20W", kannadaName: "ಟ್ಯೂಬ್ ಲೈಟ್ 20W", hindiName: "ट्यूब लाइट 20W", defaultUnit: "piece", defaultCategory: "Lighting", defaultPurchasePrice: 155.0, defaultSellingPrice: 220.0, defaultStock: 15.0),
      ],
    ),
    ShopCategoryInfo(
      id: riceRetail,
      englishName: "Rice & Grain Retail",
      kannadaName: "ಅಕ್ಕಿ ಮತ್ತು ಧಾನ್ಯ ವ್ಯಾಪಾರ",
      hindiName: "चावल एवं अनाज विक्रेता",
      icon: Icons.grain_rounded,
      themeColor: Color(0xFFF57F17),
      productCategories: [
        "Rice Varieties",
        "Wheat & Flours",
        "Pulses & Dal",
        "Millets & Grains",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "Basmati Rice Classic (ಬಾಸ್ಮತಿ ಅಕ್ಕಿ)", englishName: "Basmati Rice Classic", kannadaName: "ಬಾಸ್ಮತಿ ಅಕ್ಕಿ", hindiName: "बासमती चावल", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 85.0, defaultSellingPrice: 110.0, defaultStock: 100.0),
        CatalogProductPreset(name: "Sona Masoori Rice (ಸೋನಾ ಮಸೂರಿ ಅಕ್ಕಿ)", englishName: "Sona Masoori Rice", kannadaName: "ಸೋನಾ ಮಸೂರಿ ಅಕ್ಕಿ", hindiName: "सोना मसूरी चावल", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 45.0, defaultSellingPrice: 58.0, defaultStock: 150.0),
        CatalogProductPreset(name: "Brown Rice (ಬ್ರೌನ್ ರೈಸ್)", englishName: "Brown Rice", kannadaName: "ಬ್ರೌನ್ ರೈಸ್", hindiName: "ब्राउन राइस", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 75.0, defaultSellingPrice: 95.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Sharbati Wheat (ಗೋಧಿ)", englishName: "Sharbati Wheat", kannadaName: "ಗೋಧಿ", hindiName: "शरबती गेहूं", defaultUnit: "kg", defaultCategory: "Wheat & Flours", defaultPurchasePrice: 30.0, defaultSellingPrice: 38.0, defaultStock: 200.0),
        CatalogProductPreset(name: "Fresh Chakki Atta (ಚಕ್ಕಿ ಹಿಟ್ಟು)", englishName: "Fresh Chakki Atta", kannadaName: "ಚಕ್ಕಿ ಹಿಟ್ಟು", hindiName: "चक्की आटा", defaultUnit: "kg", defaultCategory: "Wheat & Flours", defaultPurchasePrice: 32.0, defaultSellingPrice: 40.0, defaultStock: 100.0),
        CatalogProductPreset(name: "Jowar / Sorghum (ಬಿಳಿ ಜೋಳ)", englishName: "Jowar / Sorghum", kannadaName: "ಬಿಳಿ ಜೋಳ", hindiName: "सफेद ज्वार", defaultUnit: "kg", defaultCategory: "Millets & Grains", defaultPurchasePrice: 38.0, defaultSellingPrice: 48.0, defaultStock: 80.0),
        CatalogProductPreset(name: "Ragi / Finger Millet (ರಾಗಿ)", englishName: "Ragi / Finger Millet", kannadaName: "ರಾಗಿ", hindiName: "रागी", defaultUnit: "kg", defaultCategory: "Millets & Grains", defaultPurchasePrice: 42.0, defaultSellingPrice: 55.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Desi Toor Dal (ತೊಗರಿ ಬೇಳೆ)", englishName: "Desi Toor Dal", kannadaName: "ತೊಗರಿ ಬೇಳೆ", hindiName: "देसी तूर दाल", defaultUnit: "kg", defaultCategory: "Pulses & Dal", defaultPurchasePrice: 140.0, defaultSellingPrice: 165.0, defaultStock: 60.0),
      ],
    ),
    ShopCategoryInfo(
      id: furniture,
      englishName: "Furniture",
      kannadaName: "ಪೀಠೋಪಕರಣ ಮಳಿಗೆ",
      hindiName: "फर्नीचर स्टोर",
      icon: Icons.chair_rounded,
      themeColor: Color(0xFF4E342E),
      productCategories: [
        "Chairs & Seating",
        "Tables & Desks",
        "Beds & Mattresses",
        "Storage & Almirah",
        "Home Decor",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "Plastic Molded Chair (ಪ್ಲಾಸ್ಟಿಕ್ ಕುರ್ಚಿ)", englishName: "Plastic Molded Chair", kannadaName: "ಪ್ಲಾಸ್ಟಿಕ್ ಕುರ್ಚಿ", hindiName: "प्लास्टिक कुर्सी", defaultUnit: "piece", defaultCategory: "Chairs & Seating", defaultPurchasePrice: 340.0, defaultSellingPrice: 450.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Wooden Dining Chair (ಮರದ ಕುರ್ಚಿ)", englishName: "Wooden Dining Chair", kannadaName: "ಮರದ ಕುರ್ಚಿ", hindiName: "लकड़ी की कुर्सी", defaultUnit: "piece", defaultCategory: "Chairs & Seating", defaultPurchasePrice: 850.0, defaultSellingPrice: 1200.0, defaultStock: 10.0),
        CatalogProductPreset(name: "Office Revolving Chair (ಆಫೀಸ್ ಚೇರ್)", englishName: "Office Revolving Chair", kannadaName: "ಆಫೀಸ್ ಚೇರ್", hindiName: "ऑफिस चेयर", defaultUnit: "piece", defaultCategory: "Chairs & Seating", defaultPurchasePrice: 2100.0, defaultSellingPrice: 2800.0, defaultStock: 8.0),
        CatalogProductPreset(name: "Dining Table 4-Seater (ಡೈನಿಂಗ್ ಟೇಬಲ್)", englishName: "Dining Table 4-Seater", kannadaName: "ಡೈನಿಂಗ್ ಟೇಬಲ್", hindiName: "डाइनिंग टेबल 4-सीटर", defaultUnit: "piece", defaultCategory: "Tables & Desks", defaultPurchasePrice: 4800.0, defaultSellingPrice: 6500.0, defaultStock: 4.0),
        CatalogProductPreset(name: "Study Desk (ಸ್ಟಡಿ ಟೇಬಲ್)", englishName: "Study Desk", kannadaName: "ಸ್ಟಡಿ ಟೇಬಲ್", hindiName: "स्टडी टेबल", defaultUnit: "piece", defaultCategory: "Tables & Desks", defaultPurchasePrice: 2300.0, defaultSellingPrice: 3200.0, defaultStock: 6.0),
      ],
    ),
    ShopCategoryInfo(
      id: clothing,
      englishName: "Clothing & Garments",
      kannadaName: "ಬಟ್ಟೆ ಮತ್ತು ಸಿದ್ಧ ಉಡುಪುಗಳು",
      hindiName: "कपड़ा दुकान / गारमेंट्स",
      icon: Icons.checkroom_rounded,
      themeColor: Color(0xFFC2185B),
      productCategories: [
        "Men's Wear",
        "Women's Wear",
        "Kids Wear",
        "Home Furnishing",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "Formal Cotton Shirt (ಕಾಟನ್ ಶರ್ಟ್)", englishName: "Formal Cotton Shirt", kannadaName: "ಕಾಟನ್ ಶರ್ಟ್", hindiName: "फॉर्मल शर्ट", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 450.0, defaultSellingPrice: 650.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Casual T-Shirt (ಟಿ-ಶರ್ಟ್)", englishName: "Casual T-Shirt", kannadaName: "ಟಿ-ಶರ್ಟ್", hindiName: "टी-शर्ट", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 220.0, defaultSellingPrice: 350.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Men Denim Jeans (ಜೀನ್ಸ್ ಪ್ಯಾಂಟ್)", englishName: "Men Denim Jeans", kannadaName: "ಜೀನ್ಸ್ ಪ್ಯಾಂಟ್", hindiName: "जींस पैंट", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 580.0, defaultSellingPrice: 850.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Traditional Saree (ಸೀರೆ)", englishName: "Traditional Saree", kannadaName: "ಸೀರೆ", hindiName: "साड़ी", defaultUnit: "piece", defaultCategory: "Women's Wear", defaultPurchasePrice: 750.0, defaultSellingPrice: 1100.0, defaultStock: 25.0),
      ],
    ),
    ShopCategoryInfo(
      id: hardware,
      englishName: "Hardware & Sanitary",
      kannadaName: "ಹಾರ್ಡ್‌ವೇರ್ ಮತ್ತು ಸ್ಯಾನಿಟರಿ",
      hindiName: "हार्डवेयर व सेनेटरी",
      icon: Icons.build_rounded,
      themeColor: Color(0xFF455A64),
      productCategories: [
        "Pipes & Fittings",
        "Locks & Hardware",
        "Tools & Fasteners",
        "Adhesives & Paint",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "PVC Pipe 1 inch (ಪಿವಿಸಿ ಪೈಪ್)", englishName: "PVC Pipe 1 inch", kannadaName: "ಪಿವಿಸಿ ಪೈಪ್", hindiName: "पीवीसी पाइप", defaultUnit: "piece", defaultCategory: "Pipes & Fittings", defaultPurchasePrice: 95.0, defaultSellingPrice: 140.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Brass Water Tap (ಹಿತ್ತಾಳೆ ನಲ್ಲಿ)", englishName: "Brass Water Tap", kannadaName: "ಹಿತ್ತಾಳೆ ನಲ್ಲಿ", hindiName: "पीतल नल", defaultUnit: "piece", defaultCategory: "Pipes & Fittings", defaultPurchasePrice: 180.0, defaultSellingPrice: 260.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Main Door Lock Set (ಮುಖ್ಯ ಬಾಗಿಲು ಲಾಕ್)", englishName: "Main Door Lock Set", kannadaName: "ಮುಖ್ಯ ಬಾಗಿಲು ಲಾಕ್", hindiName: "मेन डोर लॉक", defaultUnit: "piece", defaultCategory: "Locks & Hardware", defaultPurchasePrice: 520.0, defaultSellingPrice: 750.0, defaultStock: 12.0),
      ],
    ),
    ShopCategoryInfo(
      id: pharmacy,
      englishName: "Medical & Pharmacy",
      kannadaName: "ಮೆಡಿಕಲ್ ಮತ್ತು ಫಾರ್ಮಸಿ",
      hindiName: "दवा दुकान / फार्मेसी",
      icon: Icons.medication_rounded,
      themeColor: Color(0xFF00838F),
      productCategories: [
        "Tablets & Capsules",
        "Syrups & Drops",
        "First Aid & Surgical",
        "Healthcare & Hygiene",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "Paracetamol Tablets 650mg (ಪ್ಯಾರಸಿಟಮಾಲ್)", englishName: "Paracetamol Tablets 650mg", kannadaName: "ಪ್ಯಾರಸಿಟಮಾಲ್", hindiName: "पैरासिटामोल", defaultUnit: "packet", defaultCategory: "Tablets & Capsules", defaultPurchasePrice: 18.0, defaultSellingPrice: 30.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Cough Syrup 100ml (ಕೆಮ್ಮಿನ ಸಿರಪ್)", englishName: "Cough Syrup 100ml", kannadaName: "ಕೆಮ್ಮಿನ ಸಿರಪ್", hindiName: "कफ सिरप", defaultUnit: "piece", defaultCategory: "Syrups & Drops", defaultPurchasePrice: 68.0, defaultSellingPrice: 95.0, defaultStock: 25.0),
      ],
    ),
    ShopCategoryInfo(
      id: generalStore,
      englishName: "General Store",
      kannadaName: "ಜನರಲ್ ಸ್ಟೋರ್",
      hindiName: "जनरल रिटेल स्टोर",
      icon: Icons.storefront_rounded,
      themeColor: Color(0xFF283593),
      productCategories: [
        "General",
        "Stationery",
        "Snacks",
        "Household",
        "Personal Care",
      ],
      catalogPresets: [
        CatalogProductPreset(name: "Notebook / Register (ನೋಟ್‌ಬುಕ್)", englishName: "Notebook / Register", kannadaName: "ನೋಟ್‌ಬುಕ್", hindiName: "रजिस्टर / कॉपी", defaultUnit: "piece", defaultCategory: "Stationery", defaultPurchasePrice: 35.0, defaultSellingPrice: 50.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Ball Pen Packet (ಬಾಲ್ ಪೆನ್ ಪ್ಯಾಕೆಟ್)", englishName: "Ball Pen Packet", kannadaName: "ಬಾಲ್ ಪೆನ್ ಪ್ಯಾಕೆಟ್", hindiName: "पेन पैकेट", defaultUnit: "packet", defaultCategory: "Stationery", defaultPurchasePrice: 35.0, defaultSellingPrice: 50.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Battery Cells AA/AAA (ಬ್ಯಾಟರಿ ಸೆಲ್)", englishName: "Battery Cells AA/AAA", kannadaName: "ಬ್ಯಾಟರಿ ಸೆಲ್", hindiName: "सेल", defaultUnit: "piece", defaultCategory: "General", defaultPurchasePrice: 12.0, defaultSellingPrice: 20.0, defaultStock: 50.0),
      ],
    ),
  ];

  static ShopCategoryInfo getCategoryById(String? id) {
    if (id == null || id.isEmpty) {
      return categories.first;
    }
    final cleanId = id.trim().toLowerCase();
    for (final cat in categories) {
      if (cat.id.toLowerCase() == cleanId ||
          cat.englishName.toLowerCase() == cleanId ||
          cleanId.contains(cat.id.toLowerCase()) ||
          cat.id.toLowerCase().contains(cleanId)) {
        return cat;
      }
    }
    return categories.first;
  }

  static List<CatalogProductPreset> getCatalogFor(String? categoryId) {
    return getCategoryById(categoryId).catalogPresets;
  }
}
