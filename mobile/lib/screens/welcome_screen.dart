import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/language_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/language_toggle_badge.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Language Switcher Bar
              Align(
                alignment: Alignment.centerRight,
                child: const LanguageToggleBadge(),
              ),
              const Spacer(flex: 1),

              // Logo & App Name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 52,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Retailza",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lang.isKannada
                            ? "ಡಿಜಿಟಲ್ ಖಾತಾ ಮತ್ತು ಬಿಲ್ಲಿಂಗ್ ಮೆಷಿನ್"
                            : "डिजिटल बहीखाता और बिलिंग मशीन",
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),

              // Feature Highlights
              _buildFeatureItem(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primary,
                bgColor: AppColors.primarySurface,
                title: "10-Sec Fast Billing",
                localizedTag: lang.raw(kn: "ವೇಗದ ಬಿಲ್ಲಿಂಗ್", hi: "तेज़ बिलिंग"),
                subtitle: lang.isKannada
                    ? "ತ್ವರಿತ ರಶೀದಿ ಮತ್ತು ನೇರ ಲಾಭ ಲೆಕ್ಕಾಚಾರ"
                    : "Instant billing receipt with live profit capture",
              ),
              const SizedBox(height: 14),
              _buildFeatureItem(
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.debtRed,
                bgColor: AppColors.debtRedLight,
                title: "Customer Khata",
                localizedTag: lang.raw(kn: "ಉದ್ದರಿ ಖಾತೆ", hi: "उधार खाता"),
                subtitle: lang.isKannada
                    ? "ಗ್ರಾಹಕರ ಬಾಕಿ ಉಳಿಕೆ, ಜ್ಞಾಪನೆ ಮತ್ತು ಪಾವತಿಗಳು"
                    : "Track customer balances, send reminders & receive payments",
              ),
              const SizedBox(height: 14),
              _buildFeatureItem(
                icon: Icons.inventory_2_rounded,
                iconColor: AppColors.success,
                bgColor: AppColors.successLight,
                title: "Live Inventory & Alerts",
                localizedTag: lang.raw(kn: "ದಾಸ್ತಾನು ನಿರ್ವಹಣೆ", hi: "स्टॉक प्रबंधन"),
                subtitle: lang.isKannada
                    ? "ಕಡಿಮೆ ದಾಸ್ತಾನು ಎಚ್ಚರಿಕೆ ಮತ್ತು ನಿಖರ ತೂಕ ಲೆಕ್ಕ"
                    : "Fractional weights (kg/gram/litre) with low-stock warnings",
              ),
              const Spacer(flex: 2),

              // CTA Button
              CustomButton(
                text: lang.isKannada ? "Get Started / ಪ್ರಾರಂಭಿಸಿ" : "Get Started / शुरू करें",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Sub-footer
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Text(
                        "₹49/month • Zero Setup Cost • Made for India",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "© 2026 Techmasters Innovations Private Limited",
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
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

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    String? localizedTag,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (localizedTag != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        "($localizedTag)",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
