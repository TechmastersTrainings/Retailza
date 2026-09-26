import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/shop_categories.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../services/product_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceController = TextEditingController(text: "0.00");
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController(text: "10.000");
  final _thresholdController = TextEditingController(text: "5.000");

  String _selectedShopCategory = ShopCategories.provisionStore;
  String _selectedCategory = "General";
  String _selectedUnit = "piece";
  String? _selectedCatalogItem;
  bool _isSaving = false;

  List<String> _categories = ["General", "Groceries", "Grains & Pulses", "Snacks", "Dairy", "Beverages", "Personal Care"];
  final List<String> _units = ["piece", "packet", "kg", "g", "l", "ml", "meter", "box"];

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

      if (resetValues) {
        _selectedCatalogItem = null;
      }
    });
  }

  void _applyCatalogPreset(CatalogProductPreset preset) {
    setState(() {
      _selectedCatalogItem = preset.name;
      _nameController.text = preset.name;

      if (_units.contains(preset.defaultUnit)) {
        _selectedUnit = preset.defaultUnit;
      }

      if (_categories.contains(preset.defaultCategory)) {
        _selectedCategory = preset.defaultCategory;
      }

      if (preset.defaultSellingPrice > 0) {
        _sellingPriceController.text = preset.defaultSellingPrice.toStringAsFixed(2);
      }
      if (preset.defaultPurchasePrice > 0) {
        _purchasePriceController.text = preset.defaultPurchasePrice.toStringAsFixed(2);
      }
      if (preset.defaultStock > 0) {
        _stockController.text = preset.defaultStock.toStringAsFixed(3);
      }

      if (_barcodeController.text.trim().isEmpty) {
        _barcodeController.text = "${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}";
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final sellingPrice = double.parse(_sellingPriceController.text.trim());
      final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
      final stockQty = double.tryParse(_stockController.text.trim()) ?? 0.0;
      final threshold = double.tryParse(_thresholdController.text.trim()) ?? 5.0;

      await _productService.createProduct({
        'name': _nameController.text.trim(),
        if (_barcodeController.text.trim().isNotEmpty) 'barcode': _barcodeController.text.trim(),
        'category': _selectedCategory,
        'unit': _selectedUnit,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'stock_quantity': stockQty,
        'min_stock_threshold': threshold,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Add New Product (नया सामान)",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Category Indicator & Quick Switcher
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: catInfo.themeColor.withValues(alpha: 0.3), width: 1.2),
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
                    // Option to change category catalog on the fly
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

              // AUTOMATIC PRODUCT DROPDOWN FOR ACTIVE CATEGORY
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Quick Product Dropdown (${catInfo.englishName})",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Select an item to automatically autofill name, category, standard unit, and rates.",
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown for Category Specific Products
                    DropdownButtonFormField<String>(
                      value: _selectedCatalogItem,
                      isExpanded: true,
                      hint: Text(
                        "⚡ Select ${catInfo.englishName} item...",
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.primarySurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("-- Select from Catalog or Type Below --", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                        ...catalogPresets.map((preset) {
                          return DropdownMenuItem<String>(
                            value: preset.name,
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 16, color: catInfo.themeColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    preset.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "₹${preset.defaultSellingPrice.toStringAsFixed(0)}/${preset.defaultUnit}",
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const DropdownMenuItem<String>(
                          value: "__custom__",
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text("✏️ Custom Item (कस्टम सामान लिखें)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null || val == "__custom__") {
                          setState(() {
                            _selectedCatalogItem = null;
                            if (val == "__custom__") {
                              _nameController.clear();
                            }
                          });
                        } else {
                          final preset = catalogPresets.firstWhere(
                            (p) => p.name == val,
                            orElse: () => catalogPresets.first,
                          );
                          _applyCatalogPreset(preset);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick-Pick Chips Carousel
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: catalogPresets.length > 8 ? 8 : catalogPresets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final preset = catalogPresets[index];
                          final isSelected = _selectedCatalogItem == preset.name;
                          // Short name for chip
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Product Name (Editable)
              CustomTextField(
                label: "Product Name (सामान का नाम) *",
                hint: "e.g. ${catalogPresets.first.name}",
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Item name is required" : null,
              ),
              const SizedBox(height: 16),

              // Barcode with Generate Button
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Barcode (बारकोड)",
                      hint: "e.g. 890123456789",
                      controller: _barcodeController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final autoCode = "${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}";
                        _barcodeController.text = autoCode;
                      },
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text("Generate"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sub-category and Unit
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Category (श्रेणी)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        const Text("Unit (इकाई)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _units.contains(_selectedUnit) ? _selectedUnit : _units.first,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              const SizedBox(height: 16),

              // Purchase Price and Selling Price
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Purchase Cost (खरीद मूल्य)",
                      hint: "0.00",
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefix: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12), child: Text("₹")),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Selling Price (बिक्री मूल्य) *",
                      hint: "55.00",
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefix: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12), child: Text("₹")),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? "Valid price required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Initial Stock and Low Stock Alert
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Initial Stock (शुरुआती स्टॉक)",
                      hint: "10.000",
                      controller: _stockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Low Stock Alert (कम स्टॉक अलर्ट)",
                      hint: "5.000",
                      controller: _thresholdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: "Save Product (सामान सेव करें)",
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
