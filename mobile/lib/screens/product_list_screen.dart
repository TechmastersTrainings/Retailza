import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  final bool initialLowStockFilter;

  const ProductListScreen({Key? key, this.initialLowStockFilter = false}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _lowStockOnly = false;
  String _selectedCategory = "All";

  final List<String> _categories = [
    "All",
    "General",
    "Grains & Pulses",
    "Groceries",
    "Snacks",
    "Dairy",
    "Beverages"
  ];

  @override
  void initState() {
    super.initState();
    _lowStockOnly = widget.initialLowStockFilter;
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _productService.getProducts(
        search: _searchController.text.trim(),
        category: _selectedCategory,
        lowStockOnly: _lowStockOnly,
      );
      if (mounted) {
        setState(() {
          _products = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Stock & Products (सामान)",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _lowStockOnly ? AppColors.warningLight : AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _lowStockOnly ? AppColors.warning : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                _lowStockOnly ? Icons.warning_rounded : Icons.warning_amber_rounded,
                color: _lowStockOnly ? AppColors.warningDark : AppColors.textSecondary,
                size: 20,
              ),
            ),
            tooltip: "Filter Low Stock",
            onPressed: () {
              setState(() => _lowStockOnly = !_lowStockOnly);
              _fetchProducts();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          elevation: 0,
          backgroundColor: Colors.transparent,
          icon: const Icon(Icons.add_box_rounded, color: Colors.white),
          label: const Text(
            "Add Product (सामान जोड़ें)",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            );
            if (res == true) _fetchProducts();
          },
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.softShadow,
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search item name or barcode...",
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetchProducts();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => _fetchProducts(),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _fetchProducts();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : AppColors.cardBorder,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "No products found",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Tap '+ Add Product' to stock new items",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 84),
                          itemCount: _products.length,
                          itemBuilder: (ctx, i) {
                            final product = _products[i];
                            return ProductCard(
                              product: product,
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
                                );
                                if (res == true) _fetchProducts();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
