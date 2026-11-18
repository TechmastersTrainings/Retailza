import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../providers/shop_provider.dart';
import '../widgets/custom_button.dart';
import 'payment_success_screen.dart';

/// Pays the Retailza subscription through the TechMasters UPI Gateway.
///
/// The app only displays the gateway's payment details and polls the backend.
/// The backend asks the gateway whether the order is paid; the app can never
/// mark a payment as successful by itself.
class SubscriptionPaymentScreen extends StatefulWidget {
  const SubscriptionPaymentScreen({super.key});

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen>
    with WidgetsBindingObserver {
  static const Duration _pollInterval = Duration(seconds: 4);
  static const Duration _maxPolling = Duration(minutes: 20);

  SubscriptionPaymentOrder? _order;
  String _status = 'PENDING';
  String? _statusMessage;
  bool _creatingOrder = false;
  bool _checking = false;
  bool _finished = false;
  Timer? _pollTimer;
  DateTime? _pollingStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the UPI app: check immediately instead of waiting.
    if (state == AppLifecycleState.resumed && _order != null && !_finished) {
      _checkStatus();
    }
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
      _startPolling();
      if (order.upiIntent != null) {
        await _openUpiApp();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingOrder = false);
      _showSnack("Could not start payment: ${e.toString()}", AppColors.debtRed);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollingStartedAt = DateTime.now();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      final started = _pollingStartedAt;
      if (started != null && DateTime.now().difference(started) > _maxPolling) {
        _pollTimer?.cancel();
        if (mounted) setState(() {});
        return;
      }
      _checkStatus();
    });
  }

  Future<void> _checkStatus({bool userInitiated = false}) async {
    final order = _order;
    if (order == null || _checking || _finished) return;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    setState(() => _checking = true);
    final result = await shopProvider.checkSubscriptionPayment(order.orderId);
    if (!mounted) return;

    setState(() {
      _checking = false;
      if (result != null) {
        _status = result.status;
        _statusMessage = result.message;
      }
    });

    if (result == null) {
      if (userInitiated) {
        _showSnack("Could not reach Retailza server. Please try again.", AppColors.debtRed);
      }
      return;
    }

    if (result.isPaid) {
      _finished = true;
      _pollTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
      );
    } else if (result.isFinalFailure) {
      _pollTimer?.cancel();
    } else if (userInitiated && result.status == 'PENDING') {
      _showSnack("Payment not received yet. If you paid, wait a few seconds and check again.",
          AppColors.primary);
    }
  }

  Future<void> _openUpiApp() async {
    final intent = _order?.upiIntent;
    if (intent == null) return;
    final opened = await _launch(intent);
    if (!opened && mounted) {
      _showSnack("No UPI app found. Scan the QR code from another phone or open the payment page.",
          AppColors.debtRed);
    }
  }

  Future<void> _openPaymentPage() async {
    final url = _order?.paymentUrl;
    if (url == null) return;
    final opened = await _launch(url);
    if (!opened && mounted) {
      _showSnack("Could not open the payment page.", AppColors.debtRed);
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

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  bool get _pollingStopped => _pollTimer == null || !_pollTimer!.isActive;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pay with UPI"),
        centerTitle: true,
      ),
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
      if (order.isTest)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.debtRedLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            "TEST MODE: this is a sandbox payment, no real money moves.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.debtRed),
          ),
        ),
      _buildStatusBanner(),
      const SizedBox(height: 16),
      if (order.upiIntent != null) ...[
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: QrImageView(
              data: order.upiIntent!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Scan from another phone, or tap below to pay from this phone",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: "Pay with UPI app (UPI ऐप से भुगतान)",
          onPressed: _openUpiApp,
        ),
        const SizedBox(height: 10),
      ],
      OutlinedButton.icon(
        onPressed: _openPaymentPage,
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(order.upiIntent == null ? "Open secure payment page" : "Open payment page instead"),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: _checking ? null : () => _checkStatus(userInitiated: true),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text("I have paid, check status"),
      ),
      if (_status == 'EXPIRED' || _status == 'FAILED' || _pollingStopped)
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
        text = _statusMessage ?? "Your UTR is being verified.";
        break;
      case 'EXPIRED':
        icon = Icons.timer_off_outlined;
        color = AppColors.debtRed;
        text = "This payment link expired. If money was deducted, tap 'check status'; otherwise start a new payment.";
        break;
      case 'FAILED':
        icon = Icons.error_outline_rounded;
        color = AppColors.debtRed;
        text = _statusMessage ?? "Payment could not be verified. Please contact Retailza support.";
        break;
      default:
        icon = Icons.sync_rounded;
        color = AppColors.primary;
        text = _pollingStopped
            ? "Stopped checking automatically. Tap 'check status' if you have paid."
            : "Waiting for payment confirmation... (भुगतान की पुष्टि हो रही है)";
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
          if (_checking || (_status == 'PENDING' && !_pollingStopped))
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
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
