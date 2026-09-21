import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/customer_model.dart';
import '../providers/cart_provider.dart';
import '../services/customer_service.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/quantity_picker.dart';
import '../widgets/custom_button.dart';
import 'sale_payment_screen.dart';
import 'add_customer_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _discountController = TextEditingController();

  List<CustomerModel> _customers = [];
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final list = await _customerService.getCustomers();
      if (mounted) {
        setState(() {
          _customers = list;
          _isLoadingCustomers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCustomers = false);
      }
    }
  }

  void _handleProceedToCheckout(CartProvider cart) {
    if (cart.itemCount == 0) return;

    if (cart.paymentMode == 'CREDIT' && cart.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Please select a customer for Khata (Credit) sale"),
            ],
          ),
          backgroundColor: AppColors.debtRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalePaymentScreen(
          amount: cart.finalAmount,
          paymentMode: cart.paymentMode,
          customer: cart.selectedCustomer,
          discount: cart.discount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Billing Checkout (बिल चेकआउट)",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        actions: [
          if (cart.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.debtRed),
              tooltip: "Clear Bill",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text("Clear Bill?", style: TextStyle(fontWeight: FontWeight.w700)),
                    content: const Text("Are you sure you want to remove all items from this bill?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.pop(dCtx);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtRed),
                        child: const Text("Clear All"),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.itemCount == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Bill is empty (बिल खाली है)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Add items from catalog or scan barcodes to begin billing",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text("Add Products (सामान जोड़ें)"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Items in Bill (${cart.itemCount})",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Add More"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Items Card Container
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.itemList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = cart.itemList[i];
                        final isWeight = item.product.unit.toLowerCase() == "kg" || item.product.unit.toLowerCase() == "g";

                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "₹${item.subtotal.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Rate: ₹${item.product.sellingPrice.toStringAsFixed(2)} / ${item.product.unit}",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  QuantityPicker(
                                    quantity: item.quantity,
                                    unit: item.product.unit,
                                    isFractional: isWeight,
                                    onChanged: (newQty) => cart.updateQuantity(item.product.id, newQty),
                                  ),
                                  InkWell(
                                    onTap: () => cart.removeFromCart(item.product.id),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.debtRedLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.debtRed, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Payment Method Selector
                  const Text(
                    "Payment Mode (भुगतान माध्यम)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  PaymentMethodSelector(
                    selectedMode: cart.paymentMode,
                    onSelected: (mode) => cart.setPaymentMode(mode),
                  ),
                  const SizedBox(height: 20),

                  // Customer Selection for Khata
                  if (cart.paymentMode == "CREDIT") ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.debtRedLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.debtRed.withValues(alpha: 0.5), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.person_pin_rounded, color: AppColors.debtRed, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Khata Customer (ग्राहक चुनें) *",
                                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.debtRed, fontSize: 14),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                                  );
                                  _loadCustomers();
                                },
                                icon: const Icon(Icons.person_add_alt, size: 16),
                                label: const Text("New Customer"),
                                style: TextButton.styleFrom(foregroundColor: AppColors.debtRed),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_isLoadingCustomers)
                            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                          else
                            DropdownButtonFormField<CustomerModel>(
                              value: cart.selectedCustomer,
                              hint: const Text("Choose customer name"),
                              items: _customers.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    "${c.name} ${c.balance > 0 ? '(Due: ₹${c.balance.toStringAsFixed(0)})' : ''}",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                              onChanged: (c) => cart.setCustomer(c),
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.debtRed.withValues(alpha: 0.3)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Bill Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow("Subtotal (सामान का कुल)", "₹${cart.totalAmount.toStringAsFixed(2)}"),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Discount (छूट)", style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            SizedBox(
                              width: 110,
                              height: 42,
                              child: TextField(
                                controller: _discountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  prefixText: "₹ ",
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.cardBorder),
                                  ),
                                ),
                                onChanged: (val) {
                                  final d = double.tryParse(val) ?? 0.0;
                                  cart.setDiscount(d);
                                },
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Payable (देय राशि)",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Text(
                              "₹${cart.finalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Proceed to Payment CTA
                  CustomButton(
                    text: "Proceed to Payment (₹${cart.finalAmount.toStringAsFixed(2)})",
                    onPressed: () => _handleProceedToCheckout(cart),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
