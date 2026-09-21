import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/customer_model.dart';
import '../models/sale_model.dart';
import '../providers/cart_provider.dart';
import '../providers/shop_provider.dart';
import '../services/customer_service.dart';
import '../widgets/upi_qr_helper.dart';
import 'sale_success_screen.dart';
import 'add_customer_screen.dart';

class SalePaymentScreen extends StatefulWidget {
  final double amount;
  final String paymentMode; // CASH, UPI, CREDIT
  final CustomerModel? customer;
  final double discount;

  const SalePaymentScreen({
    Key? key,
    required this.amount,
    required this.paymentMode,
    this.customer,
    this.discount = 0.0,
  }) : super(key: key);

  @override
  State<SalePaymentScreen> createState() => _SalePaymentScreenState();
}

class _SalePaymentScreenState extends State<SalePaymentScreen> {
  final CustomerService _customerService = CustomerService();
  bool _isProcessing = false;
  CustomerModel? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
  }

  Future<void> _handlePaymentDecision(String paymentStatus) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // If unpaid and no customer selected, ask shopkeeper to select a customer
    if (paymentStatus == "UNPAID" && _selectedCustomer == null) {
      final chosenCustomer = await _showCustomerSelectionSheet();
      if (chosenCustomer == null) return;
      setState(() => _selectedCustomer = chosenCustomer);
      cart.setCustomer(chosenCustomer);
    }

    setState(() => _isProcessing = true);

    final SaleModel? sale = await cart.checkout(paymentStatus: paymentStatus);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (sale != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SaleSuccessScreen(sale: sale)),
        (route) => route.isFirst,
      );
    } else if (cart.checkoutError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.checkoutError!),
          backgroundColor: AppColors.debtRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<CustomerModel?> _showCustomerSelectionSheet() async {
    List<CustomerModel> customers = [];
    bool loading = true;

    try {
      customers = await _customerService.getCustomers();
      loading = false;
    } catch (_) {
      loading = false;
    }

    if (!mounted) return null;

    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Assign Unpaid Bill to Khata (ग्राहक चुनें)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                      );
                      try {
                        final updated = await _customerService.getCustomers();
                        setSheetState(() => customers = updated);
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text("Add New Khata Customer"),
                  ),
                  const Divider(),
                  if (loading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (customers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No customers found. Create a new customer above."),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (cCtx, idx) {
                          final cust = customers[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.debtRedLight,
                              child: Text(
                                cust.name.isNotEmpty ? cust.name[0].toUpperCase() : "C",
                                style: const TextStyle(color: AppColors.debtRed, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Current Due: ₹${cust.balance.toStringAsFixed(2)}"),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            onTap: () => Navigator.pop(ctx, cust),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleUploadQr(ShopProvider shopProvider) async {
    final result = await UpiQrHelper.showQrPickerSheet(
      context,
      currentUpiId: shopProvider.shop?.upiId,
      currentImage: shopProvider.shop?.upiQrImage,
    );

    if (result != null) {
      final success = await shopProvider.updateUpiQr(
        upiQrImage: result['upi_qr_image'],
        upiId: result['upi_id'],
      );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text("UPI QR Code updated successfully!"),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final shop = shopProvider.shop;
    final hasQrImage = shop?.upiQrImage != null && shop!.upiQrImage!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Receive Payment (भुगतान)",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Total Bill Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.paymentMode == "UPI"
                            ? "UPI ONLINE PAYMENT"
                            : widget.paymentMode == "CREDIT"
                                ? "KHATA CREDIT PAYMENT"
                                : "CASH PAYMENT",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₹${widget.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.discount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Includes ₹${widget.discount.toStringAsFixed(2)} store discount",
                        style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Mode Specific Content
              if (widget.paymentMode == "UPI") ...[
                // Shop UPI QR Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: AppColors.upiPurple, size: 22),
                              SizedBox(width: 8),
                              Text(
                                "Customer Scanner QR",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _handleUploadQr(shopProvider),
                            icon: Icon(hasQrImage ? Icons.edit : Icons.upload_file, size: 16),
                            label: Text(hasQrImage ? "Change" : "Upload QR"),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.upiPurple,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (hasQrImage) ...[
                        UpiQrHelper.buildQrImageWidget(shop.upiQrImage, height: 210),
                        const SizedBox(height: 12),
                        if (shop.upiId != null && shop.upiId!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.upiPurpleLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "UPI ID: ${shop.upiId}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.upiPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        const Text(
                          "Ask customer to scan with Google Pay, PhonePe, Paytm, or BHIM",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.upiPurpleLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.upiPurple.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.upiPurple),
                              const SizedBox(height: 10),
                              const Text(
                                "No UPI Scanner Uploaded Yet",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.upiPurple),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Take a screenshot of your GPay, PhonePe, or Paytm QR standee and upload it here so customers can scan directly from your phone screen.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () => _handleUploadQr(shopProvider),
                                icon: const Icon(Icons.upload, size: 18),
                                label: const Text("Upload QR Screenshot (स्क्रीनशॉट अपलोड करें)"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.upiPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (widget.paymentMode == "CASH") ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.successLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payments_rounded, size: 54, color: AppColors.success),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Cash Collection (नकद संग्रह)",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Collect ₹${widget.amount.toStringAsFixed(2)} in cash from customer.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.debtRed.withValues(alpha: 0.3)),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: AppColors.debtRedLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_rounded, size: 44, color: AppColors.debtRed),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _selectedCustomer?.name ?? "Khata Customer",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Previous Due: ₹${(_selectedCustomer?.balance ?? 0.0).toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("New Khata Debt to Add:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(
                            "+ ₹${widget.amount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.debtRed),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("New Total Balance:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                            "₹${((_selectedCustomer?.balance ?? 0.0) + widget.amount).toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.debtRed),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Shop Owner Decision Instruction
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tap below to confirm payment status & record profit:",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dual Kirana Decision Buttons (Paid vs Unpaid)
              if (_isProcessing)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else ...[
                // Paid Button (Primary Emerald)
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.profitGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handlePaymentDecision("PAID"),
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 22, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              "Paid (भुगतान प्राप्त हुआ) • ₹${widget.amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Unpaid Button (Khata / Pending Debt)
                OutlinedButton.icon(
                  onPressed: () => _handlePaymentDecision("UNPAID"),
                  icon: const Icon(Icons.pending_actions_rounded, size: 20, color: AppColors.debtRed),
                  label: Text(
                    widget.paymentMode == "CREDIT"
                        ? "Confirm Khata (उधार में दर्ज करें)"
                        : "Unpaid / Khata (भुगतान बाकी - उधार में जोड़ें)",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.debtRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.debtRed,
                    side: const BorderSide(color: AppColors.debtRed, width: 1.5),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
