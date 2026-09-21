import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/sale_model.dart';
import '../services/sale_service.dart';
import 'sale_details_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SaleService _saleService = SaleService();
  List<SaleModel> _sales = [];
  bool _isLoading = true;
  String? _paymentFilter;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoading = true);
    try {
      final list = await _saleService.getSales(paymentMode: _paymentFilter);
      setState(() {
        _sales = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History (बिक्री इतिहास)"),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip("All (सभी)", null),
                const SizedBox(width: 8),
                _buildFilterChip("Cash (नकद)", "CASH"),
                const SizedBox(width: 8),
                _buildFilterChip("UPI (ऑनलाइन)", "UPI"),
                const SizedBox(width: 8),
                _buildFilterChip("Khata (उधार)", "CREDIT"),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.receipt_outlined, size: 54, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text("No bills found for this filter", style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchSales,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _sales.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final sale = _sales[i];
                            return Card(
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => SaleDetailsScreen(saleId: sale.id)),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: sale.paymentMode == "CREDIT"
                                      ? AppColors.debtRedLight
                                      : sale.paymentMode == "UPI"
                                          ? AppColors.upiPurpleLight
                                          : AppColors.successLight,
                                  child: Icon(
                                    sale.paymentMode == "CREDIT"
                                        ? Icons.menu_book
                                        : sale.paymentMode == "UPI"
                                            ? Icons.qr_code
                                            : Icons.payments,
                                    color: sale.paymentMode == "CREDIT"
                                        ? AppColors.debtRed
                                        : sale.paymentMode == "UPI"
                                            ? AppColors.upiPurple
                                            : AppColors.success,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Bill #${sale.id}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      "₹${sale.finalAmount.toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      sale.customerName ?? "${sale.items.length} items",
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      dateFormat.format(sale.createdAt),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? mode) {
    final isSelected = _paymentFilter == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        setState(() => _paymentFilter = mode);
        _fetchSales();
      },
    );
  }
}
