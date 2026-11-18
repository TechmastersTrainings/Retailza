import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../providers/shop_provider.dart';
import '../widgets/custom_button.dart';
import 'payment_success_screen.dart';

/// Pays the ₹49 Retailza subscription directly into Retailza's own UPI ID.
///
/// Flow: create an order -> show the UPI QR / intent -> owner pays with any UPI
/// app -> owner enters the 12-digit UTR from the receipt -> the backend verifies
/// it and activates the month. No payment aggregator and no middleman.
class SubscriptionPaymentScreen extends StatefulWidget {
  const SubscriptionPaymentScreen({super.key});

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  SubscriptionPaymentOrder? _order;
  String _status = 'PENDING';
  String? _statusMessage;
  bool _creatingOrder = false;
  bool _submitting = false;

  final TextEditingController _utrController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    setState(() {
      _creatingOrder = true;
      _statusMessage = null;
      _status = 'PENDING';
    });

    try {
      final order = await shopProvider.createSubscriptionOrder();
      if (!mounted) return;
      setState(() {
        _order = order;
        _creatingOrder = false;
      });
      await _openUpiApp();
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingOrder = false);
      _showSnack("Could not start payment: ${e.toString()}", AppColors.debtRed);
    }
  }

  Future<void> _submitUtr() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final order = _order;
    if (order == null || _submitting) return;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final utr = _utrController.text.replaceAll(RegExp(r'\s+'), '');
    setState(() => _submitting = true);

    try {
      final result = await shopProvider.submitSubscriptionUtr(order.orderId, utr);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _status = result.status;
        _statusMessage = result.message;
      });

      if (result.isPaid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(e.toString(), AppColors.debtRed);
    }
  }

  Future<void> _openUpiApp() async {
    final intent = _order?.upiIntent;
    if (intent == null || intent.isEmpty) return;
    final opened = await _launch(intent);
    if (!opened && mounted) {
      _showSnack("No UPI app found. Scan the QR from another phone, then enter the UTR below.",
          AppColors.debtRed);
    }
  }

  Future<bool> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  void _copyUpiId() {
    final vpa = _order?.upiId;
    if (vpa == null || vpa.isEmpty) return;
    Clipboard.setData(ClipboardData(text: vpa));
    _showSnack("UPI ID copied", AppColors.primary);
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay with UPI"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlanCard(),
              const SizedBox(height: 20),
              if (_order == null) ..._buildStart() else ..._buildPayment(_order!),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "Payment is confirmed by the Retailza server, not the app",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final amount = _order?.amount ?? 49.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Retailza SaaS Plan (30 Days)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Includes POS Billing & Khata modules",
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStart() {
    return [
      const Text(
        "Pay instantly with Google Pay, PhonePe, Paytm, BHIM or any UPI app.",
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      const SizedBox(height: 20),
      CustomButton(
        text: "Pay ₹49.00 with UPI (भुगतान करें)",
        isLoading: _creatingOrder,
        onPressed: _createOrder,
      ),
    ];
  }

  List<Widget> _buildPayment(SubscriptionPaymentOrder order) {
    return [
      _buildStatusBanner(),
      const SizedBox(height: 16),
      if (order.upiIntent.isNotEmpty) ...[
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: QrImageView(
              data: order.upiIntent,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (order.upiId.isNotEmpty)
          InkWell(
            onTap: _copyUpiId,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    order.upiId,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        const SizedBox(height: 14),
        CustomButton(
          text: "Pay with UPI app (UPI ऐप से भुगतान)",
          onPressed: _openUpiApp,
        ),
      ],
      const SizedBox(height: 22),
      const Divider(),
      const SizedBox(height: 10),
      const Text(
        "After paying, enter the 12-digit UTR / UPI reference number",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      const SizedBox(height: 4),
      const Text(
        "You will find it in your UPI app's payment receipt / transaction details.",
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      Form(
        key: _formKey,
        child: TextFormField(
          controller: _utrController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          enabled: _status != 'SUCCESS',
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: "12-digit UTR",
            hintText: "e.g. 412345678901",
            counterText: "",
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            final value = (v ?? '').replaceAll(RegExp(r'\s+'), '');
            if (!RegExp(r'^\d{12}$').hasMatch(value)) {
              return "Enter the 12-digit reference number from your receipt";
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 10),
      CustomButton(
        text: "Confirm payment (भुगतान की पुष्टि करें)",
        isLoading: _submitting,
        onPressed: _status == 'SUCCESS' ? null : _submitUtr,
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: _creatingOrder ? null : _createOrder,
        child: const Text("Start a new payment"),
      ),
    ];
  }

  Widget _buildStatusBanner() {
    late final IconData icon;
    late final Color color;
    late final String text;

    switch (_status) {
      case 'REVIEW':
        icon = Icons.hourglass_top_rounded;
        color = AppColors.primary;
        text = _statusMessage ??
            "UTR received. Your subscription will activate once we verify the payment.";
        break;
      case 'FAILED':
        icon = Icons.error_outline_rounded;
        color = AppColors.debtRed;
        text = _statusMessage ?? "Payment could not be verified. Please contact Retailza support.";
        break;
      default:
        icon = Icons.qr_code_2_rounded;
        color = AppColors.primary;
        text = "Scan or tap to pay ₹49, then enter the UTR below to activate.";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}
