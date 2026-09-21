import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/network/api_client.dart';

class StockTransactionScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const StockTransactionScreen({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<StockTransactionScreen> createState() => _StockTransactionScreenState();
}

class _StockTransactionScreenState extends State<StockTransactionScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final res = await ApiClient.get("/inventory/${widget.productId}/transactions");
      setState(() {
        _transactions = res as List<dynamic>;
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
        title: Text("Audit Log: ${widget.productName}"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text("No stock transactions recorded yet"))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final tx = _transactions[i] as Map<String, dynamic>;
                    final double changeQty = double.tryParse(tx['change_quantity'].toString()) ?? 0.0;
                    final double balanceQty = double.tryParse(tx['balance_quantity'].toString()) ?? 0.0;
                    final String type = tx['transaction_type'] as String;
                    final String? reason = tx['reason'] as String?;
                    final dt = DateTime.tryParse(tx['created_at'].toString()) ?? DateTime.now();

                    final isPositive = changeQty > 0;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPositive ? AppColors.successLight : AppColors.debtRedLight,
                          child: Icon(
                            isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isPositive ? AppColors.success : AppColors.debtRed,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "${isPositive ? '+' : ''}$changeQty",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isPositive ? AppColors.success : AppColors.debtRed,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reason != null && reason.isNotEmpty)
                              Text(reason, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Balance: $balanceQty", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(dateFormat.format(dt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
