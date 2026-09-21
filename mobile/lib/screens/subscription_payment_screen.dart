import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/constants/app_colors.dart';
import '../providers/shop_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import 'payment_success_screen.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  const SubscriptionPaymentScreen({super.key});

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  String _selectedMethod = "UPI"; // UPI, CARD, NETBANKING
  late Razorpay _razorpay;
  String? _currentOrderId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _initiateRazorpayPayment() async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isProcessing = true);

    try {
      final orderData = await shopProvider.createSubscriptionOrder();
      _currentOrderId = orderData['order_id'] as String?;
      final keyId = orderData['key_id'] as String? ?? "rzp_test_TWXn6r1HPxwz0r";
      final rawAmount = orderData['amount'];
      final amountInPaise = (double.parse(rawAmount.toString()) * 100).toInt();

      final mobile = authProvider.user?.mobileNumber ?? "";
      final shopName = shopProvider.shop?.shopName ?? "Kirana Store";

      var options = {
        'key': keyId,
        'amount': amountInPaise,
        'name': 'Retailza Kirana SaaS',
        'description': '30-Day Subscription for $shopName',
        'order_id': _currentOrderId,
        'timeout': 300,
        'prefill': {
          'contact': mobile,
          'email': 'support@retailza.in',
        },
        'theme': {
          'color': '#0F172A',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to initialize payment: ${e.toString()}"),
          backgroundColor: AppColors.debtRed,
        ),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    final success = await shopProvider.verifySubscriptionPayment(
      orderId: response.orderId ?? _currentOrderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.errorMessage ?? "Payment verification failed"),
          backgroundColor: AppColors.debtRed,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message ?? 'Transaction cancelled'}"),
        backgroundColor: AppColors.debtRed,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External wallet selected: ${response.walletName}"),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _processMockSandboxPayment() async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    final success = await shopProvider.completeMockPayment();

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.errorMessage ?? "Payment processing failed"),
          backgroundColor: AppColors.debtRed,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final isLoading = _isProcessing || shopProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Razorpay Secure Checkout"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Retailza SaaS Plan (30 Days)",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Includes POS Billing & Khata modules",
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      "₹49.00",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Select Payment Method",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildPaymentTile(
                title: "UPI (Google Pay / PhonePe / Paytm)",
                subtitle: "Instant payment with any UPI app",
                icon: Icons.qr_code_2,
                id: "UPI",
              ),
              const SizedBox(height: 10),
              _buildPaymentTile(
                title: "Debit / Credit Card",
                subtitle: "Visa, Mastercard, RuPay",
                icon: Icons.credit_card,
                id: "CARD",
              ),
              const SizedBox(height: 10),
              _buildPaymentTile(
                title: "Net Banking",
                subtitle: "All Indian national & private banks",
                icon: Icons.account_balance,
                id: "NETBANKING",
              ),
              const Spacer(),
              CustomButton(
                text: "Pay ₹49.00 Now (सुरक्षित भुगतान)",
                isLoading: isLoading,
                onPressed: _initiateRazorpayPayment,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: isLoading ? null : _processMockSandboxPayment,
                  icon: const Icon(Icons.flash_on, size: 16, color: AppColors.textMuted),
                  label: const Text(
                    "Dev Sandbox Bypass (Emulator Instant Activate)",
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          "100% Encrypted & Verified by Razorpay",
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Supported: UPI Intent • Cards • NetBanking",
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String id,
  }) {
    final bool isSelected = _selectedMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedMethod,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
          ],
        ),
      ),
    );
  }
}
