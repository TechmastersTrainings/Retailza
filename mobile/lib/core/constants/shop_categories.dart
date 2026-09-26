import 'package:flutter/material.dart';

class CatalogProductPreset {
  final String name;
  final String defaultUnit;
  final String defaultCategory;
  final double defaultPurchasePrice;
  final double defaultSellingPrice;
  final double defaultStock;

  const CatalogProductPreset({
    required this.name,
    required this.defaultUnit,
    required this.defaultCategory,
    this.defaultPurchasePrice = 0.0,
    this.defaultSellingPrice = 0.0,
    this.defaultStock = 10.0,
  });
}

class ShopCategoryInfo {
  final String id;
  final String englishName;
  final String hindiName;
  final IconData icon;
  final Color themeColor;
  final List<String> productCategories;
  final List<CatalogProductPreset> catalogPresets;

  const ShopCategoryInfo({
    required this.id,
    required this.englishName,
    required this.hindiName,
    required this.icon,
    required this.themeColor,
    required this.productCategories,
    required this.catalogPresets,
  });

  String get displayName => "$englishName ($hindiName)";
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
        CatalogProductPreset(name: "Rice (चावल)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 42.0, defaultSellingPrice: 55.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Wheat / Atta (गेहूं का आटा)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 34.0, defaultSellingPrice: 42.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Sugar (चीनी / शक्कर)", defaultUnit: "kg", defaultCategory: "Groceries", defaultPurchasePrice: 38.0, defaultSellingPrice: 44.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Salt / Tata Salt (नमक)", defaultUnit: "packet", defaultCategory: "Groceries", defaultPurchasePrice: 22.0, defaultSellingPrice: 28.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Tea Leaves / Chai Patti (चाय पत्ती)", defaultUnit: "packet", defaultCategory: "Beverages", defaultPurchasePrice: 110.0, defaultSellingPrice: 140.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Toor Dal / Arhar Dal (तूर दाल)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 135.0, defaultSellingPrice: 160.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Moong Dal (मूंग दाल)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 100.0, defaultSellingPrice: 120.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Chana Dal (चना दाल)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 75.0, defaultSellingPrice: 90.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Mustard Oil / Sarson Tel (सरसों तेल 1L)", defaultUnit: "l", defaultCategory: "Cooking Oil", defaultPurchasePrice: 125.0, defaultSellingPrice: 150.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Sunflower Refined Oil (रिफाइंड तेल 1L)", defaultUnit: "l", defaultCategory: "Cooking Oil", defaultPurchasePrice: 115.0, defaultSellingPrice: 135.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Turmeric Powder / Haldi (हल्दी)", defaultUnit: "packet", defaultCategory: "Spices & Masala", defaultPurchasePrice: 26.0, defaultSellingPrice: 35.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Red Chilli Powder / Mirch (लाल मिर्च)", defaultUnit: "packet", defaultCategory: "Spices & Masala", defaultPurchasePrice: 35.0, defaultSellingPrice: 45.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Coriander Powder / Dhaniya (धनिया)", defaultUnit: "packet", defaultCategory: "Spices & Masala", defaultPurchasePrice: 30.0, defaultSellingPrice: 40.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Besan / Gram Flour (बेसन 1kg)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 70.0, defaultSellingPrice: 85.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Maida (मैदा)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 32.0, defaultSellingPrice: 40.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Suji / Rava (सूजी)", defaultUnit: "kg", defaultCategory: "Grains & Pulses", defaultPurchasePrice: 35.0, defaultSellingPrice: 45.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Biscuits / Cookies (बिस्कुट)", defaultUnit: "packet", defaultCategory: "Snacks", defaultPurchasePrice: 8.0, defaultSellingPrice: 10.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Bathing Soap (साबुन)", defaultUnit: "piece", defaultCategory: "Personal Care", defaultPurchasePrice: 28.0, defaultSellingPrice: 35.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Detergent Powder 1kg (डिटर्जेंट)", defaultUnit: "packet", defaultCategory: "Groceries", defaultPurchasePrice: 52.0, defaultSellingPrice: 65.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Toothpaste 100g (टूथपेस्ट)", defaultUnit: "piece", defaultCategory: "Personal Care", defaultPurchasePrice: 48.0, defaultSellingPrice: 60.0, defaultStock: 25.0),
      ],
    ),
    ShopCategoryInfo(
      id: electrical,
      englishName: "Electrical",
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
        CatalogProductPreset(name: "Modular Switch 6A (स्विच 6A)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 30.0, defaultSellingPrice: 45.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Modular Switch 16A Power (पावर स्विच 16A)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 65.0, defaultSellingPrice: 95.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Switch Board 4+1 (स्विच बोर्ड 4+1)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 120.0, defaultSellingPrice: 180.0, defaultStock: 15.0),
        CatalogProductPreset(name: "Switch Board 8+2 (स्विच बोर्ड 8+2)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 220.0, defaultSellingPrice: 320.0, defaultStock: 12.0),
        CatalogProductPreset(name: "Bell Push Button (डोर बेल बटन)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 38.0, defaultSellingPrice: 60.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Copper Wire 1.0 sq mm (कॉपर वायर 1.0mm)", defaultUnit: "meter", defaultCategory: "Wires & Cables", defaultPurchasePrice: 13.0, defaultSellingPrice: 18.0, defaultStock: 180.0),
        CatalogProductPreset(name: "Copper Wire 1.5 sq mm (कॉपर वायर 1.5mm)", defaultUnit: "meter", defaultCategory: "Wires & Cables", defaultPurchasePrice: 19.0, defaultSellingPrice: 26.0, defaultStock: 180.0),
        CatalogProductPreset(name: "Copper Wire 2.5 sq mm (कॉपर वायर 2.5mm)", defaultUnit: "meter", defaultCategory: "Wires & Cables", defaultPurchasePrice: 31.0, defaultSellingPrice: 42.0, defaultStock: 90.0),
        CatalogProductPreset(name: "Flexible Wire Coil 90m (वायर बंडल)", defaultUnit: "packet", defaultCategory: "Wires & Cables", defaultPurchasePrice: 680.0, defaultSellingPrice: 850.0, defaultStock: 8.0),
        CatalogProductPreset(name: "MCB Single Pole 16A (सिंगल पोल एमसीबी)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 110.0, defaultSellingPrice: 160.0, defaultStock: 20.0),
        CatalogProductPreset(name: "MCB Double Pole 32A (डीपी एमसीबी)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 270.0, defaultSellingPrice: 380.0, defaultStock: 10.0),
        CatalogProductPreset(name: "LED Bulb 9W (एलईडी बल्ब 9W)", defaultUnit: "piece", defaultCategory: "Lighting", defaultPurchasePrice: 60.0, defaultSellingPrice: 90.0, defaultStock: 40.0),
        CatalogProductPreset(name: "LED Bulb 12W (एलईडी बल्ब 12W)", defaultUnit: "piece", defaultCategory: "Lighting", defaultPurchasePrice: 90.0, defaultSellingPrice: 130.0, defaultStock: 30.0),
        CatalogProductPreset(name: "LED Tube Light 20W (ट्यूब लाइट 20W)", defaultUnit: "piece", defaultCategory: "Lighting", defaultPurchasePrice: 155.0, defaultSellingPrice: 220.0, defaultStock: 15.0),
        CatalogProductPreset(name: "Power Socket 16A (पावर सॉकेट 16A)", defaultUnit: "piece", defaultCategory: "Switches & Boards", defaultPurchasePrice: 58.0, defaultSellingPrice: 85.0, defaultStock: 25.0),
        CatalogProductPreset(name: "3-Pin Top Plug (3-पिन प्लग)", defaultUnit: "piece", defaultCategory: "Accessories & Tools", defaultPurchasePrice: 32.0, defaultSellingPrice: 50.0, defaultStock: 35.0),
        CatalogProductPreset(name: "Ceiling Fan 1200mm (सीलिंग फैन)", defaultUnit: "piece", defaultCategory: "Fans & Appliances", defaultPurchasePrice: 1250.0, defaultSellingPrice: 1650.0, defaultStock: 6.0),
        CatalogProductPreset(name: "Exhaust Fan 9 inch (एग्जॉस्ट पंखा)", defaultUnit: "piece", defaultCategory: "Fans & Appliances", defaultPurchasePrice: 720.0, defaultSellingPrice: 950.0, defaultStock: 5.0),
        CatalogProductPreset(name: "Insulation PVC Tape (इंसुलेशन टेप)", defaultUnit: "piece", defaultCategory: "Accessories & Tools", defaultPurchasePrice: 9.0, defaultSellingPrice: 15.0, defaultStock: 60.0),
        CatalogProductPreset(name: "Conduit PVC Pipe (कंड्यूट पाइप 25mm)", defaultUnit: "piece", defaultCategory: "Accessories & Tools", defaultPurchasePrice: 45.0, defaultSellingPrice: 65.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Extension Spike Board (एक्सटेंशन बोर्ड)", defaultUnit: "piece", defaultCategory: "Accessories & Tools", defaultPurchasePrice: 190.0, defaultSellingPrice: 280.0, defaultStock: 8.0),
        CatalogProductPreset(name: "Angle Bulb Holder (बल्ब होल्डर)", defaultUnit: "piece", defaultCategory: "Accessories & Tools", defaultPurchasePrice: 18.0, defaultSellingPrice: 30.0, defaultStock: 40.0),
      ],
    ),
    ShopCategoryInfo(
      id: riceRetail,
      englishName: "Rice & Grain Retail",
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
        CatalogProductPreset(name: "Basmati Rice Classic (बासमती चावल)", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 85.0, defaultSellingPrice: 110.0, defaultStock: 100.0),
        CatalogProductPreset(name: "Sona Masoori Rice (सोना मसूरी चावल)", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 45.0, defaultSellingPrice: 58.0, defaultStock: 150.0),
        CatalogProductPreset(name: "Kolam Rice (कोलम चावल)", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 50.0, defaultSellingPrice: 65.0, defaultStock: 120.0),
        CatalogProductPreset(name: "Wada Kolam Rice (वाडा कोलम)", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 60.0, defaultSellingPrice: 75.0, defaultStock: 80.0),
        CatalogProductPreset(name: "Boiled Rice / Ponni (उबला चावल)", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 38.0, defaultSellingPrice: 48.0, defaultStock: 150.0),
        CatalogProductPreset(name: "Tukda Rice / Broken (टुकड़ा चावल)", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 28.0, defaultSellingPrice: 36.0, defaultStock: 100.0),
        CatalogProductPreset(name: "Brown Rice (ब्राउन राइस)", defaultUnit: "kg", defaultCategory: "Rice Varieties", defaultPurchasePrice: 75.0, defaultSellingPrice: 95.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Sharbati Wheat (शरबती गेहूं)", defaultUnit: "kg", defaultCategory: "Wheat & Flours", defaultPurchasePrice: 30.0, defaultSellingPrice: 38.0, defaultStock: 200.0),
        CatalogProductPreset(name: "Lokwan Wheat (लोकवन गेहूं)", defaultUnit: "kg", defaultCategory: "Wheat & Flours", defaultPurchasePrice: 25.0, defaultSellingPrice: 32.0, defaultStock: 200.0),
        CatalogProductPreset(name: "Fresh Chakki Atta (चक्की आटा)", defaultUnit: "kg", defaultCategory: "Wheat & Flours", defaultPurchasePrice: 32.0, defaultSellingPrice: 40.0, defaultStock: 100.0),
        CatalogProductPreset(name: "Jowar / Sorghum (सफेद ज्वार)", defaultUnit: "kg", defaultCategory: "Millets & Grains", defaultPurchasePrice: 38.0, defaultSellingPrice: 48.0, defaultStock: 80.0),
        CatalogProductPreset(name: "Bajra / Pearl Millet (बाजरा)", defaultUnit: "kg", defaultCategory: "Millets & Grains", defaultPurchasePrice: 26.0, defaultSellingPrice: 35.0, defaultStock: 80.0),
        CatalogProductPreset(name: "Ragi / Finger Millet (रागी)", defaultUnit: "kg", defaultCategory: "Millets & Grains", defaultPurchasePrice: 42.0, defaultSellingPrice: 55.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Desi Toor Dal (देसी तूर दाल)", defaultUnit: "kg", defaultCategory: "Pulses & Dal", defaultPurchasePrice: 140.0, defaultSellingPrice: 165.0, defaultStock: 60.0),
        CatalogProductPreset(name: "Kabuli Chana (सफेद चना / छोले)", defaultUnit: "kg", defaultCategory: "Pulses & Dal", defaultPurchasePrice: 105.0, defaultSellingPrice: 130.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Desi Kala Chana (काला चना)", defaultUnit: "kg", defaultCategory: "Pulses & Dal", defaultPurchasePrice: 68.0, defaultSellingPrice: 85.0, defaultStock: 60.0),
        CatalogProductPreset(name: "Poha / Flattened Rice (मोटा पोहा)", defaultUnit: "kg", defaultCategory: "Millets & Grains", defaultPurchasePrice: 38.0, defaultSellingPrice: 50.0, defaultStock: 50.0),
      ],
    ),
    ShopCategoryInfo(
      id: furniture,
      englishName: "Furniture",
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
        CatalogProductPreset(name: "Plastic Molded Chair (प्लास्टिक कुर्सी)", defaultUnit: "piece", defaultCategory: "Chairs & Seating", defaultPurchasePrice: 340.0, defaultSellingPrice: 450.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Wooden Dining Chair (लकड़ी की कुर्सी)", defaultUnit: "piece", defaultCategory: "Chairs & Seating", defaultPurchasePrice: 850.0, defaultSellingPrice: 1200.0, defaultStock: 10.0),
        CatalogProductPreset(name: "Office Revolving Chair (ऑफिस चेयर)", defaultUnit: "piece", defaultCategory: "Chairs & Seating", defaultPurchasePrice: 2100.0, defaultSellingPrice: 2800.0, defaultStock: 8.0),
        CatalogProductPreset(name: "Dining Table 4-Seater (डाइनिंग टेबल 4-सीटर)", defaultUnit: "piece", defaultCategory: "Tables & Desks", defaultPurchasePrice: 4800.0, defaultSellingPrice: 6500.0, defaultStock: 4.0),
        CatalogProductPreset(name: "Office / Study Desk (स्टडी टेबल)", defaultUnit: "piece", defaultCategory: "Tables & Desks", defaultPurchasePrice: 2300.0, defaultSellingPrice: 3200.0, defaultStock: 6.0),
        CatalogProductPreset(name: "Center Table / Coffee Table (टी टेबल)", defaultUnit: "piece", defaultCategory: "Tables & Desks", defaultPurchasePrice: 1300.0, defaultSellingPrice: 1800.0, defaultStock: 6.0),
        CatalogProductPreset(name: "Double Bed King Size 6x6 (किंग साइज बेड)", defaultUnit: "piece", defaultCategory: "Beds & Mattresses", defaultPurchasePrice: 10500.0, defaultSellingPrice: 14500.0, defaultStock: 3.0),
        CatalogProductPreset(name: "Single Bed 3x6 (सिंगल बेड)", defaultUnit: "piece", defaultCategory: "Beds & Mattresses", defaultPurchasePrice: 4100.0, defaultSellingPrice: 5500.0, defaultStock: 5.0),
        CatalogProductPreset(name: "Steel Almirah / Wardrobe (स्टील अलमारी)", defaultUnit: "piece", defaultCategory: "Storage & Almirah", defaultPurchasePrice: 6500.0, defaultSellingPrice: 8500.0, defaultStock: 4.0),
        CatalogProductPreset(name: "Wooden 3-Door Wardrobe (लकड़ी अलमारी)", defaultUnit: "piece", defaultCategory: "Storage & Almirah", defaultPurchasePrice: 9200.0, defaultSellingPrice: 12500.0, defaultStock: 3.0),
        CatalogProductPreset(name: "Sofa Set 3+1+1 (सोफा सेट 5-सीटर)", defaultUnit: "piece", defaultCategory: "Chairs & Seating", defaultPurchasePrice: 13500.0, defaultSellingPrice: 18000.0, defaultStock: 2.0),
        CatalogProductPreset(name: "Shoe Rack Cabinet (शू रैक)", defaultUnit: "piece", defaultCategory: "Storage & Almirah", defaultPurchasePrice: 1600.0, defaultSellingPrice: 2200.0, defaultStock: 6.0),
        CatalogProductPreset(name: "Dressing Table with Mirror (ड्रेसिंग टेबल)", defaultUnit: "piece", defaultCategory: "Storage & Almirah", defaultPurchasePrice: 3200.0, defaultSellingPrice: 4500.0, defaultStock: 4.0),
        CatalogProductPreset(name: "Coir & Foam Mattress 6x6 (गद्दा / मैट्रेस)", defaultUnit: "piece", defaultCategory: "Beds & Mattresses", defaultPurchasePrice: 4800.0, defaultSellingPrice: 6200.0, defaultStock: 4.0),
      ],
    ),
    ShopCategoryInfo(
      id: clothing,
      englishName: "Clothing & Garments",
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
        CatalogProductPreset(name: "Formal Cotton Shirt (फॉर्मल शर्ट)", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 450.0, defaultSellingPrice: 650.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Casual T-Shirt (टी-शर्ट)", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 220.0, defaultSellingPrice: 350.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Men Denim Jeans (जींस पैंट)", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 580.0, defaultSellingPrice: 850.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Cotton Formal Trousers (पैंट)", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 480.0, defaultSellingPrice: 700.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Track Pants / Lower (लोअर)", defaultUnit: "piece", defaultCategory: "Men's Wear", defaultPurchasePrice: 250.0, defaultSellingPrice: 380.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Ladies Designer Kurti (कुर्ती)", defaultUnit: "piece", defaultCategory: "Women's Wear", defaultPurchasePrice: 360.0, defaultSellingPrice: 550.0, defaultStock: 35.0),
        CatalogProductPreset(name: "Traditional Saree (साड़ी)", defaultUnit: "piece", defaultCategory: "Women's Wear", defaultPurchasePrice: 750.0, defaultSellingPrice: 1100.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Salwar Suit Set (सूट सेट)", defaultUnit: "piece", defaultCategory: "Women's Wear", defaultPurchasePrice: 680.0, defaultSellingPrice: 950.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Leggings / Plazo (लेगिंग्स)", defaultUnit: "piece", defaultCategory: "Women's Wear", defaultPurchasePrice: 180.0, defaultSellingPrice: 280.0, defaultStock: 35.0),
        CatalogProductPreset(name: "Kids Wear Set (बच्चों के कपड़े)", defaultUnit: "piece", defaultCategory: "Kids Wear", defaultPurchasePrice: 290.0, defaultSellingPrice: 450.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Double Bedsheet with Pillow Covers (चादर)", defaultUnit: "piece", defaultCategory: "Home Furnishing", defaultPurchasePrice: 320.0, defaultSellingPrice: 480.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Cotton Bath Towel (तौलिया)", defaultUnit: "piece", defaultCategory: "Home Furnishing", defaultPurchasePrice: 140.0, defaultSellingPrice: 220.0, defaultStock: 25.0),
      ],
    ),
    ShopCategoryInfo(
      id: hardware,
      englishName: "Hardware & Sanitary",
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
        CatalogProductPreset(name: "PVC Pipe 1 inch (पीवीसी पाइप)", defaultUnit: "piece", defaultCategory: "Pipes & Fittings", defaultPurchasePrice: 95.0, defaultSellingPrice: 140.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Brass Water Tap (पीतल नल)", defaultUnit: "piece", defaultCategory: "Pipes & Fittings", defaultPurchasePrice: 180.0, defaultSellingPrice: 260.0, defaultStock: 20.0),
        CatalogProductPreset(name: "Main Door Lock Set (मेन डोर लॉक)", defaultUnit: "piece", defaultCategory: "Locks & Hardware", defaultPurchasePrice: 520.0, defaultSellingPrice: 750.0, defaultStock: 12.0),
        CatalogProductPreset(name: "Padlock 65mm (ताला)", defaultUnit: "piece", defaultCategory: "Locks & Hardware", defaultPurchasePrice: 155.0, defaultSellingPrice: 220.0, defaultStock: 25.0),
        CatalogProductPreset(name: "SS Door Hinges 4 inch (कब्जे)", defaultUnit: "piece", defaultCategory: "Locks & Hardware", defaultPurchasePrice: 28.0, defaultSellingPrice: 45.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Tower Bolt 6 inch (सिटकनी)", defaultUnit: "piece", defaultCategory: "Locks & Hardware", defaultPurchasePrice: 38.0, defaultSellingPrice: 60.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Steel Wire Nails (कील)", defaultUnit: "kg", defaultCategory: "Tools & Fasteners", defaultPurchasePrice: 68.0, defaultSellingPrice: 95.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Drywall Screws Box (पेंच बॉक्स)", defaultUnit: "packet", defaultCategory: "Tools & Fasteners", defaultPurchasePrice: 110.0, defaultSellingPrice: 160.0, defaultStock: 20.0),
        CatalogProductPreset(name: "M-Seal Epoxy Putty (एम-सील)", defaultUnit: "packet", defaultCategory: "Adhesives & Paint", defaultPurchasePrice: 14.0, defaultSellingPrice: 20.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Fevicol SH 1kg (फेविकोल)", defaultUnit: "kg", defaultCategory: "Adhesives & Paint", defaultPurchasePrice: 185.0, defaultSellingPrice: 240.0, defaultStock: 15.0),
        CatalogProductPreset(name: "Hand Hammer 500g (हथौड़ा)", defaultUnit: "piece", defaultCategory: "Tools & Fasteners", defaultPurchasePrice: 120.0, defaultSellingPrice: 180.0, defaultStock: 10.0),
        CatalogProductPreset(name: "Screw Driver Set (पेचकस सेट)", defaultUnit: "piece", defaultCategory: "Tools & Fasteners", defaultPurchasePrice: 145.0, defaultSellingPrice: 220.0, defaultStock: 15.0),
      ],
    ),
    ShopCategoryInfo(
      id: pharmacy,
      englishName: "Medical & Pharmacy",
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
        CatalogProductPreset(name: "Paracetamol Tablets 650mg (पैरासिटामोल)", defaultUnit: "packet", defaultCategory: "Tablets & Capsules", defaultPurchasePrice: 18.0, defaultSellingPrice: 30.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Cough Syrup 100ml (कफ सिरप)", defaultUnit: "piece", defaultCategory: "Syrups & Drops", defaultPurchasePrice: 68.0, defaultSellingPrice: 95.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Antacid Tablets / Gel (एसिडिटी दवा)", defaultUnit: "packet", defaultCategory: "Tablets & Capsules", defaultPurchasePrice: 26.0, defaultSellingPrice: 40.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Pain Relief Gel (दर्द निवारक जेल)", defaultUnit: "piece", defaultCategory: "Healthcare & Hygiene", defaultPurchasePrice: 75.0, defaultSellingPrice: 110.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Bandage Roll & Cotton (पट्टी व रुई)", defaultUnit: "packet", defaultCategory: "First Aid & Surgical", defaultPurchasePrice: 20.0, defaultSellingPrice: 35.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Antiseptic Liquid 100ml (डेटॉल)", defaultUnit: "piece", defaultCategory: "First Aid & Surgical", defaultPurchasePrice: 48.0, defaultSellingPrice: 65.0, defaultStock: 30.0),
        CatalogProductPreset(name: "ORS Electrolyte Sachet (ओआरएस घोल)", defaultUnit: "packet", defaultCategory: "Healthcare & Hygiene", defaultPurchasePrice: 15.0, defaultSellingPrice: 22.0, defaultStock: 60.0),
        CatalogProductPreset(name: "Digital Thermometer (थर्मामीटर)", defaultUnit: "piece", defaultCategory: "First Aid & Surgical", defaultPurchasePrice: 120.0, defaultSellingPrice: 180.0, defaultStock: 15.0),
        CatalogProductPreset(name: "Surgical Face Mask (मास्क)", defaultUnit: "packet", defaultCategory: "First Aid & Surgical", defaultPurchasePrice: 30.0, defaultSellingPrice: 50.0, defaultStock: 50.0),
      ],
    ),
    ShopCategoryInfo(
      id: generalStore,
      englishName: "General Store",
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
        CatalogProductPreset(name: "Notebook / Register (रजिस्टर / कॉपी)", defaultUnit: "piece", defaultCategory: "Stationery", defaultPurchasePrice: 35.0, defaultSellingPrice: 50.0, defaultStock: 40.0),
        CatalogProductPreset(name: "Ball Pen Packet (पेन पैकेट)", defaultUnit: "packet", defaultCategory: "Stationery", defaultPurchasePrice: 35.0, defaultSellingPrice: 50.0, defaultStock: 30.0),
        CatalogProductPreset(name: "Battery Cells AA/AAA (सेल)", defaultUnit: "piece", defaultCategory: "General", defaultPurchasePrice: 12.0, defaultSellingPrice: 20.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Potato Chips / Namkeen (नमकीन / चिप्स)", defaultUnit: "packet", defaultCategory: "Snacks", defaultPurchasePrice: 16.0, defaultSellingPrice: 20.0, defaultStock: 50.0),
        CatalogProductPreset(name: "Floor Cleaner / Phenyl (फिनाइल)", defaultUnit: "piece", defaultCategory: "Household", defaultPurchasePrice: 55.0, defaultSellingPrice: 75.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Mosquito Repellent Liquid (मच्छर दवा)", defaultUnit: "piece", defaultCategory: "Household", defaultPurchasePrice: 65.0, defaultSellingPrice: 85.0, defaultStock: 25.0),
        CatalogProductPreset(name: "Hair Oil 100ml (हेयर ऑयल)", defaultUnit: "piece", defaultCategory: "Personal Care", defaultPurchasePrice: 38.0, defaultSellingPrice: 50.0, defaultStock: 30.0),
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
