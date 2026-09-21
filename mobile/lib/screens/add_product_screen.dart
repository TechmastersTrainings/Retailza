import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
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

  String _selectedCategory = "General";
  String _selectedUnit = "piece";
  bool _isSaving = false;

  final List<String> _categories = ["General", "Grains & Pulses", "Groceries", "Snacks", "Dairy", "Beverages", "Personal Care"];
  final List<String> _units = ["piece", "packet", "kg", "g", "l", "ml"];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product (नया सामान)"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: "Product Name (सामान का नाम) *",
                hint: "e.g. Aashirvaad Atta 5kg, Fortune Oil 1L",
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Item name is required" : null,
              ),
              const SizedBox(height: 16),
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
                    child: OutlinedButton(
                      onPressed: () {
                        final autoCode = "${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}";
                        _barcodeController.text = autoCode;
                      },
                      child: const Text("Generate"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Category (श्रेणी)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
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
                          value: _selectedUnit,
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 14)))).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Purchase Price (खरीद मूल्य)",
                      hint: "45.00",
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
                      label: "Low Stock Alert (कम स्टॉक चेतावनी)",
                      hint: "5.000",
                      controller: _thresholdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "Save Product (सामान सेव करें)",
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
