import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/custom_button.dart';
import 'stock_transaction_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductService _productService = ProductService();
  late ProductModel _currentProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  void _showRestockDialog() {
    final qtyController = TextEditingController(text: "10");
    final reasonController = TextEditingController(text: "Supplier delivery");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Restock (नया माल जोड़ें)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Quantity to Add (${_currentProduct.unit})",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: "Note / Supplier"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text);
              if (qty != null && qty > 0) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final updated = await _productService.restock(_currentProduct.id, qty, reason: reasonController.text);
                  setState(() {
                    _currentProduct = updated;
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Restocked successfully!"), backgroundColor: AppColors.success),
                  );
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.debtRed),
                  );
                }
              }
            },
            child: const Text("Add Stock"),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog() {
    final qtyController = TextEditingController();
    String reason = "Damage / Spoilage (खराब हो गया)";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Stock Adjustment (स्टॉक सुधार)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: "Change Qty (e.g. -2 for damage, +1 for return)",
                  suffixText: _currentProduct.unit,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: reason,
                items: const [
                  DropdownMenuItem(value: "Damage / Spoilage (खराब हो गया)", child: Text("Damage / Spoilage")),
                  DropdownMenuItem(value: "Customer Return (वापसी)", child: Text("Customer Return")),
                  DropdownMenuItem(value: "Inventory Count Correction", child: Text("Audit Correction")),
                ],
                onChanged: (v) => setDialogState(() => reason = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final qty = double.tryParse(qtyController.text);
                if (qty != null) {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    final updated = await _productService.adjustStock(_currentProduct.id, qty, reason: reason);
                    setState(() {
                      _currentProduct = updated;
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Stock adjusted successfully!"), backgroundColor: AppColors.success),
                    );
                  } catch (e) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.debtRed),
                    );
                  }
                }
              },
              child: const Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Deactivate Product?"),
        content: Text("Are you sure you want to deactivate '${_currentProduct.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Deactivate"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _productService.deleteProduct(_currentProduct.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentProduct.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Stock Audit History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StockTransactionScreen(
                    productId: _currentProduct.id,
                    productName: _currentProduct.name,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Deactivate",
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Available Stock", style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            Text(
                              "${_currentProduct.stockQuantity} ${_currentProduct.unit}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _currentProduct.isLowStock ? AppColors.warning : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (_currentProduct.isLowStock) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(6)),
                            child: const Text("Low Stock Alert (Threshold: 5)", style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        const Divider(height: 24),
                        _infoRow("Selling Price (बिक्री दर)", "₹${_currentProduct.sellingPrice.toStringAsFixed(2)} / ${_currentProduct.unit}"),
                        const SizedBox(height: 8),
                        _infoRow("Purchase Price (लागत दर)", "₹${_currentProduct.purchasePrice.toStringAsFixed(2)}"),
                        const SizedBox(height: 8),
                        _infoRow("Category", _currentProduct.category),
                        const SizedBox(height: 8),
                        _infoRow("Barcode", _currentProduct.barcode ?? "None"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: "+ Restock (माल जोड़ें)",
                          icon: Icons.add_box_outlined,
                          backgroundColor: AppColors.primary,
                          onPressed: _showRestockDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: "Adjust (सुधार)",
                          icon: Icons.tune,
                          isOutlined: true,
                          onPressed: _showAdjustDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockTransactionScreen(
                            productId: _currentProduct.id,
                            productName: _currentProduct.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_edu),
                    label: const Text("View Stock Movement History (स्टॉक इतिहास)"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
