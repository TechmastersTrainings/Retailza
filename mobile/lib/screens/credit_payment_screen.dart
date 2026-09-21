import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/customer_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CreditPaymentScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  final double currentBalance;

  const CreditPaymentScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
    required this.currentBalance,
  }) : super(key: key);

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController(text: "Cash payment");
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentBalance > 0) {
      _amountController.text = widget.currentBalance.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment amount must be greater than 0")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _customerService.recordCreditPayment(
        widget.customerId,
        amount,
        note: _noteController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Khata payment received and recorded!"), backgroundColor: AppColors.success),
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
        title: Text("Receive Payment: ${widget.customerName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        const Text("Current Due (कुल बाकी)", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Text(
                      "₹${widget.currentBalance.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.debtRed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: "Amount Received (जमा राशि) *",
                hint: "e.g. 500.00",
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Text("₹")),
                validator: (v) => (v == null || double.tryParse(v) == null) ? "Valid amount required" : null,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text("Full Due: ₹${widget.currentBalance.toStringAsFixed(2)}"),
                    onPressed: () => _amountController.text = widget.currentBalance.toStringAsFixed(2),
                  ),
                  ActionChip(
                    label: const Text("₹100"),
                    onPressed: () => _amountController.text = "100.00",
                  ),
                  ActionChip(
                    label: const Text("₹500"),
                    onPressed: () => _amountController.text = "500.00",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Payment Note / Mode (विवरण)",
                hint: "e.g. Cash payment / GPay transfer",
                controller: _noteController,
              ),
              const Spacer(),
              CustomButton(
                text: "Save Payment (जमा दर्ज करें)",
                backgroundColor: AppColors.success,
                isLoading: _isSaving,
                onPressed: _handlePayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
