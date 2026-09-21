import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'product_details_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final list = await _productService.getProducts();
      setState(() {
        _products = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStockItems = _products.where((p) => p.isLowStock).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Manager (स्टॉक प्रबंधक)"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchInventory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overview Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lowStockItems.isNotEmpty ? AppColors.warningLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: lowStockItems.isNotEmpty ? AppColors.warning : AppColors.success,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lowStockItems.isNotEmpty ? Icons.warning_rounded : Icons.check_circle_rounded,
                          color: lowStockItems.isNotEmpty ? AppColors.warning : AppColors.success,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lowStockItems.isNotEmpty
                                    ? "${lowStockItems.length} items need restock!"
                                    : "All stock levels healthy!",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: lowStockItems.isNotEmpty ? AppColors.warning : AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Total ${_products.length} products tracked in inventory",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (lowStockItems.isNotEmpty) ...[
                    const Text(
                      "Low Stock Alert Items (तुरंत मंगाएं)",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warning),
                    ),
                    const SizedBox(height: 10),
                    ...lowStockItems.map((p) => _buildStockRow(p, isWarning: true)),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    "All Inventory Items (सभी सामान)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  ..._products.map((p) => _buildStockRow(p, isWarning: false)),
                ],
              ),
            ),
    );
  }

  Widget _buildStockRow(ProductModel p, {required bool isWarning}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: p)),
          );
          if (res == true) _fetchInventory();
        },
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("Category: ${p.category} • Rate: ₹${p.sellingPrice.toStringAsFixed(2)}"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: p.isLowStock ? AppColors.warningLight : AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.isLowStock ? AppColors.warning : AppColors.cardBorder),
          ),
          child: Text(
            "${p.stockQuantity} ${p.unit}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: p.isLowStock ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
