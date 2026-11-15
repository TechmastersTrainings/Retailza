import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/shop_categories.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../services/product_service.dart';
import '../widgets/custom_button.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  // Selected values (All Dropdown Fashion)
  String _selectedShopCategory = ShopCategories.provisionStore;
  String? _selectedProductName;
  String _selectedCategory = "Groceries";
  String _selectedUnit = "kg";
  double _selectedSellingPrice = 50.0;
  double _selectedPurchasePrice = 40.0;
  double _selectedStock = 20.0;
  double _selectedThreshold = 5.0;

  bool _isCustomName = false;
  final _customNameController = TextEditingController();
  bool _isSaving = false;

  List<String> _categories = ["General", "Groceries", "Grains & Pulses", "Snacks", "Dairy", "Beverages", "Personal Care"];
  final List<String> _units = ["kg", "packet", "piece", "l", "g", "ml", "meter", "box"];

  // Standard Kirana Selling Prices for Dropdown
  static const List<double> _sellingPricePresets = [
    5.0, 10.0, 15.0, 20.0, 25.0, 28.0, 30.0, 35.0, 40.0, 42.0, 44.0, 45.0, 50.0,
    55.0, 60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 95.0, 100.0, 110.0, 120.0,
    125.0, 130.0, 135.0, 140.0, 150.0, 160.0, 175.0, 180.0, 200.0, 220.0, 250.0,
    265.0, 275.0, 300.0, 350.0, 400.0, 500.0, 600.0, 750.0, 1000.0, 1200.0, 1500.0, 2000.0
  ];

  // Standard Kirana Purchase Costs for Dropdown
  static const List<double> _purchasePricePresets = [
    0.0, 5.0, 8.0, 10.0, 12.0, 15.0, 18.0, 20.0, 22.0, 25.0, 26.0, 28.0, 30.0,
    32.0, 34.0, 35.0, 38.0, 40.0, 42.0, 45.0, 48.0, 50.0, 52.0, 55.0, 60.0,
    65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 100.0, 110.0, 115.0, 120.0, 125.0,
    135.0, 140.0, 150.0, 175.0, 200.0, 220.0, 250.0, 300.0, 400.0, 500.0, 700.0, 900.0, 1000.0
  ];

  // Stock Quantity Presets for Dropdown
  static const List<double> _stockPresets = [
    5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 40.0, 50.0, 75.0, 100.0, 150.0, 200.0, 500.0
  ];

  // Low Stock Alert Threshold Presets
  static const List<double> _thresholdPresets = [
    2.0, 5.0, 10.0, 15.0, 20.0, 25.0
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initShopCategory();
    });
  }

  void _initShopCategory() {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentShop = shopProvider.shop ?? authProvider.shop;
    final categoryId = currentShop?.category ?? ShopCategories.provisionStore;

    _updateCategoryCatalog(categoryId, resetValues: false);
  }

  void _updateCategoryCatalog(String categoryId, {bool resetValues = true}) {
    final catInfo = ShopCategories.getCategoryById(categoryId);
    setState(() {
      _selectedShopCategory = catInfo.id;
      final newCategories = ["General", ...catInfo.productCategories];
      _categories = newCategories.toSet().toList();

      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.first;
      }

      if (catInfo.catalogPresets.isNotEmpty) {
        final firstPreset = catInfo.catalogPresets.first;
        _applyCatalogPreset(firstPreset);
      }
    });
  }

  void _applyCatalogPreset(CatalogProductPreset preset) {
    setState(() {
      _selectedProductName = preset.name;
      _isCustomName = false;
      _customNameController.text = preset.name;

      if (_units.contains(preset.defaultUnit)) {
        _selectedUnit = preset.defaultUnit;
      }

      if (_categories.contains(preset.defaultCategory)) {
        _selectedCategory = preset.defaultCategory;
      }

      // Auto-select prices and stocks if in presets, or find closest
      _selectedSellingPrice = _closestPreset(preset.defaultSellingPrice, _sellingPricePresets);
      _selectedPurchasePrice = _closestPreset(preset.defaultPurchasePrice, _purchasePricePresets);
      _selectedStock = _closestPreset(preset.defaultStock, _stockPresets);
      _selectedThreshold = 5.0;
    });
  }

  double _closestPreset(double target, List<double> presets) {
    if (presets.contains(target)) return target;
    return presets.reduce((a, b) => (a - target).abs() < (b - target).abs() ? a : b);
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final finalName = _isCustomName
        ? _customNameController.text.trim()
        : (_selectedProductName ?? "");

    if (finalName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or enter a product name"), backgroundColor: AppColors.debtRed),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _productService.createProduct({
        'name': finalName,
        'category': _selectedCategory,
        'unit': _selectedUnit,
        'purchase_price': _selectedPurchasePrice,
        'selling_price': _selectedSellingPrice,
        'stock_quantity': _selectedStock,
        'min_stock_threshold': _selectedThreshold,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully!"), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.debtRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catInfo = ShopCategories.getCategoryById(_selectedShopCategory);
    final catalogPresets = catInfo.catalogPresets;

    // Ensure currently selected prices exist in options
    final sellingPriceOptions = {..._sellingPricePresets, _selectedSellingPrice}.toList()..sort();
    final purchasePriceOptions = {..._purchasePricePresets, _selectedPurchasePrice}.toList()..sort();
    final stockOptions = {..._stockPresets, _selectedStock}.toList()..sort();
    final thresholdOptions = {..._thresholdPresets, _selectedThreshold}.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Add New Product (नया सामान)",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Category Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: catInfo.themeColor.withValues(alpha: 0.25), width: 1.2),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: catInfo.themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(catInfo.icon, color: catInfo.themeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Store Category: ",
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                catInfo.englishName,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: catInfo.themeColor),
                              ),
                            ],
                          ),
                          Text(
                            catInfo.hindiName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: "Change Catalog Category",
                      icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                      onSelected: (catId) => _updateCategoryCatalog(catId),
                      itemBuilder: (context) {
                        return ShopCategories.categories.map((cat) {
                          return PopupMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.themeColor, size: 18),
                                const SizedBox(width: 10),
                                Text(cat.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 1. PRODUCT NAME DROPDOWN (ONLY NAMES, NO PRICES)
              const Text(
                "Product Name (सामान का नाम) *",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProductName,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
                hint: const Text("-- Select Product Name (सामान चुनें) --", style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                items: [
                  ...catalogPresets.map((preset) {
                    return DropdownMenuItem<String>(
                      value: preset.name,
                      child: Text(
                        preset.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  const DropdownMenuItem<String>(
                    value: "__custom__",
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text("✏️ Other / Custom Name (दूसरा नाम लिखें)", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == "__custom__") {
                    setState(() {
                      _isCustomName = true;
                      _selectedProductName = "__custom__";
                      _customNameController.clear();
                    });
                  } else if (val != null) {
                    final preset = catalogPresets.firstWhere((p) => p.name == val, orElse: () => catalogPresets.first);
                    _applyCatalogPreset(preset);
                  }
                },
              ),

              // Optional Custom Name Input (Only if Other/Custom selected)
              if (_isCustomName) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Enter Custom Product Name",
                    hintText: "e.g. Masoor Dal 500g",
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Quick Chips for 1-tap name selection
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: catalogPresets.length > 10 ? 10 : catalogPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset = catalogPresets[index];
                    final isSelected = _selectedProductName == preset.name;
                    final shortName = preset.name.split(" (").first;
                    return ChoiceChip(
                      label: Text(shortName, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                      selected: isSelected,
                      selectedColor: catInfo.themeColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: isSelected ? catInfo.themeColor : AppColors.textPrimary),
                      onSelected: (_) => _applyCatalogPreset(preset),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // 2. CATEGORY & UNIT DROPDOWNS
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Category (श्रेणी)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Unit (इकाई)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _units.contains(_selectedUnit) ? _selectedUnit : _units.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3. PURCHASE PRICE & SELLING PRICE DROPDOWNS
              Row(
                children: [
                  // Purchase Cost Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Purchase Cost (खरीद मूल्य)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<double>(
                          value: purchasePriceOptions.contains(_selectedPurchasePrice) ? _selectedPurchasePrice : purchasePriceOptions.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: purchasePriceOptions.map((price) {
                            return DropdownMenuItem<double>(
                              value: price,
                              child: Text(
                                price == 0.0 ? "₹ 0.00 (Free)" : "₹ ${price.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedPurchasePrice = v ?? 0.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Selling Price Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Selling Price (बिक्री मूल्य) *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<double>(
                          value: sellingPriceOptions.contains(_selectedSellingPrice) ? _selectedSellingPrice : sellingPriceOptions.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: AppColors.primarySurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                          ),
                          items: sellingPriceOptions.map((price) {
                            return DropdownMenuItem<double>(
                              value: price,
                              child: Text(
                                "₹ ${price.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSellingPrice = v ?? 50.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4. INITIAL STOCK & LOW STOCK ALERT DROPDOWNS
              Row(
                children: [
                  // Initial Stock Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Initial Stock (शुरुआती स्टॉक)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<double>(
                          value: stockOptions.contains(_selectedStock) ? _selectedStock : stockOptions.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: stockOptions.map((qty) {
                            return DropdownMenuItem<double>(
                              value: qty,
                              child: Text(
                                "${qty.toInt()} $_selectedUnit",
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedStock = v ?? 20.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Low Stock Alert Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Low Stock Alert (कम स्टॉक)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<double>(
                          value: thresholdOptions.contains(_selectedThreshold) ? _selectedThreshold : thresholdOptions.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: thresholdOptions.map((qty) {
                            return DropdownMenuItem<double>(
                              value: qty,
                              child: Text(
                                "${qty.toInt()} $_selectedUnit",
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.warning),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedThreshold = v ?? 5.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // SAVE BUTTON
              CustomButton(
                text: "Save Product (सामान सेव करें)",
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
