import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'shop_setup_screen.dart';
import 'subscription_screen.dart';
import 'main_navigation_screen.dart';

class OtpScreen extends StatefulWidget {
  final String identifier;
  final String? debugOtp;

  const OtpScreen({
    super.key,
    required this.identifier,
    this.debugOtp,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  String? _currentDebugOtp;

  @override
  void initState() {
    super.initState();
    _currentDebugOtp = widget.debugOtp;
    if (_currentDebugOtp != null) {
      _otpController.text = _currentDebugOtp!;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String get _destinationDisplay {
    if (widget.identifier.contains('@')) {
      return widget.identifier;
    }
    return "+91 ${widget.identifier}";
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter complete OTP code"),
          backgroundColor: AppColors.debtRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(widget.identifier, otp);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? "Verification failed"),
          backgroundColor: AppColors.debtRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Check if user already has a shop configured
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    await shopProvider.loadShopData();

    if (!mounted) return;

    final currentShop = authProvider.shop ?? shopProvider.shop;
    if (currentShop == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ShopSetupScreen()),
        (route) => false,
      );
    } else {
      if (authProvider.shop == null && shopProvider.shop != null) {
        authProvider.setShop(shopProvider.shop!);
      }

      if (!shopProvider.isSubscriptionActive) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleResend() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newOtp = await authProvider.requestOtp(widget.identifier);
    if (!mounted) return;
    if (newOtp != null) {
      setState(() {
        _currentDebugOtp = newOtp;
        _otpController.text = newOtp;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New OTP auto-filled: $newOtp"),
          backgroundColor: AppColors.successDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? "OTP request sent."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.successDark, size: 28),
              ),
              const SizedBox(height: 24),
              const Text(
                "Verify OTP Code",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter 6-digit code sent to $_destinationDisplay",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_currentDebugOtp != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.successDark, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Auto-filled Dev OTP: $_currentDebugOtp",
                        style: const TextStyle(
                          color: AppColors.successDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CustomTextField(
                label: "6-Digit OTP Code",
                hint: "123456",
                controller: _otpController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: "Verify & Proceed (सत्यापित करें)",
                isLoading: authProvider.isLoading,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: authProvider.isLoading ? null : _handleResend,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    "Didn't receive code? Resend OTP",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
