import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'otp_screen.dart';
import 'legal_screen.dart';
import '../core/constants/legal_content.dart';
import '../core/constants/api_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmail = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_checkInputType);
  }

  void _checkInputType() {
    final text = _identifierController.text.trim();
    final isEmailNow = text.contains('@');
    if (isEmailNow != _isEmail) {
      setState(() {
        _isEmail = isEmailNow;
      });
    }
  }

  @override
  void dispose() {
    _identifierController.removeListener(_checkInputType);
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _identifierController.text.trim();

    final debugOtp = await authProvider.requestOtp(identifier);

    if (!mounted) return;

    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
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
        builder: (_) => OtpScreen(
          identifier: identifier,
          debugOtp: debugOtp,
        ),
      ),
    );
  }

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.dns_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Server API URL", style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Default connects directly to Render Cloud (no Wi-Fi needed). You can switch to local PC Wi-Fi if testing offline.",
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "Base API URL",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Quick Presets:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.cloud_done, size: 14, color: AppColors.primary),
                        label: const Text("Cloud Live (Render)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = ApiConstants.defaultCloudUrl;
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.wifi, size: 14),
                        label: const Text("Local Wi-Fi (192.168.1.7)", style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = "http://192.168.1.7:8000/api";
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.phone_android, size: 14),
                        label: const Text("Emulator (10.0.2.2)", style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = "http://10.0.2.2:8000/api";
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  await ApiConstants.setBaseUrl(controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Server URL saved: ${ApiConstants.baseUrl}")),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppColors.primary),
            tooltip: "Server IP / Network",
            onPressed: () => _showServerConfigDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isEmail ? Icons.email_outlined : Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Enter Mobile or Email",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "We will send a 6-digit OTP verification code to log in or register your Kirana store.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                CustomTextField(
                  label: "Mobile Number or Email (मोबाइल या ईमेल)",
                  hint: _isEmail ? "name@email.com" : "9876543210 or email",
                  controller: _identifierController,
                  keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.text,
                  prefix: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isEmail) ...[
                          const Icon(Icons.alternate_email_rounded, color: AppColors.primary, size: 18),
                        ] else ...[
                          const Text(
                            "+91",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter mobile number or email address";
                    }
                    final trimmed = val.trim();
                    if (trimmed.contains('@')) {
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(trimmed)) {
                        return "Enter a valid email address";
                      }
                      return null;
                    }
                    final cleaned = trimmed.replaceAll(RegExp(r'\D'), '');
                    if (cleaned.length != 10) {
                      return "Enter a valid 10-digit mobile number or email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: "Send OTP (ओटीपी भेजें)",
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSendOtp,
                ),
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "By continuing, you agree to Retailza ",
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LegalScreen(initialTabIndex: 1),
                                ),
                              );
                            },
                            child: const Text(
                              "Terms of Service",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(
                            " & ",
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LegalScreen(initialTabIndex: 0),
                                ),
                              );
                            },
                            child: const Text(
                              "Privacy Policy",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        LegalContent.copyrightNotice,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
