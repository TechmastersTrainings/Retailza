import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../widgets/custom_button.dart';
import 'credit_payment_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailsScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final CustomerService _customerService = CustomerService();
  CustomerModel? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await _customerService.getCustomerDetails(widget.customerId);
      setState(() {
        _customer = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.name ?? "Customer Khata"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
              ? const Center(child: Text("Customer not found"))
              : RefreshIndicator(
                  onRefresh: _fetchDetails,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Balance Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _customer!.balance > 0 ? AppColors.debtRedLight : AppColors.successLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _customer!.balance > 0 ? AppColors.debtRed : AppColors.success,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _customer!.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (_customer!.mobileNumber != null) ...[
                              const SizedBox(height: 4),
                              Text("+91 ${_customer!.mobileNumber!}", style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              _customer!.balance > 0 ? "Total Due (बाकी राशि)" : "No Dues (कोई बाकी नहीं)",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _customer!.balance > 0 ? AppColors.debtRed : AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${_customer!.balance.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _customer!.balance > 0 ? AppColors.debtRed : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: "Receive Payment (जमा)",
                              icon: Icons.payments,
                              backgroundColor: AppColors.success,
                              onPressed: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreditPaymentScreen(
                                      customerId: _customer!.id,
                                      customerName: _customer!.name,
                                      currentBalance: _customer!.balance,
                                    ),
                                  ),
                                );
                                if (res == true) _fetchDetails();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: "Remind (तगादा)",
                              icon: Icons.share,
                              isOutlined: true,
                              textColor: const Color(0xFF25D366),
                              backgroundColor: const Color(0xFF25D366),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Reminder sent: ₹${_customer!.balance.toStringAsFixed(2)} due"),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Passbook / Ledger Timeline
                      const Text(
                        "Khata Ledger History (खाता बही)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      if (_customer!.recentTransactions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text("No transactions recorded yet", style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ..._customer!.recentTransactions.map((tx) {
                          final isCreditGiven = tx.transactionType == "CREDIT_GIVEN";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCreditGiven ? AppColors.debtRedLight : AppColors.successLight,
                                child: Icon(
                                  isCreditGiven ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
                                  color: isCreditGiven ? AppColors.debtRed : AppColors.success,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isCreditGiven ? "Credit Given (उधार दिया)" : "Payment Received (रुपए मिले)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isCreditGiven ? AppColors.debtRed : AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    "${isCreditGiven ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isCreditGiven ? AppColors.debtRed : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(tx.note ?? (isCreditGiven ? "Goods on credit" : "Cash payment"), style: const TextStyle(fontSize: 12)),
                                  Text(dateFormat.format(tx.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
    );
  }
}
