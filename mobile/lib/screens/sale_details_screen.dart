import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/sale_model.dart';
import '../services/sale_service.dart';

class SaleDetailsScreen extends StatefulWidget {
  final int saleId;

  const SaleDetailsScreen({Key? key, required this.saleId}) : super(key: key);

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  final SaleService _saleService = SaleService();
  SaleModel? _sale;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final s = await _saleService.getSaleDetail(widget.saleId);
      setState(() {
        _sale = s;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text("Receipt #${widget.saleId}"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sale == null
              ? const Center(child: Text("Receipt not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Receipt #${_sale!.id}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              _sale!.paymentMode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _sale!.paymentMode == "CREDIT" ? AppColors.debtRed : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(dateFormat.format(_sale!.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (_sale!.customerName != null) ...[
                          const SizedBox(height: 8),
                          Text("Customer: ${_sale!.customerName}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                        const Divider(height: 24),
                        const Text("Items Purchased", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        ..._sale!.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("${it.productName} (${it.quantity % 1 == 0 ? it.quantity.toInt() : it.quantity})")),
                                Text("₹${it.subtotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal:", style: TextStyle(color: AppColors.textSecondary)),
                            Text("₹${_sale!.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (_sale!.discount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Discount:", style: TextStyle(color: AppColors.debtRed)),
                              Text("-₹${_sale!.discount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.debtRed)),
                            ],
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Paid:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("₹${_sale!.finalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
