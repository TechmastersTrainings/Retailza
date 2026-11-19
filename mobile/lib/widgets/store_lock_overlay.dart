import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/language_provider.dart';
import '../providers/shop_provider.dart';
import '../screens/subscription_payment_screen.dart';

/// Non-dismissible full-screen locked state shown at day 30 if no active payment
class StoreLockOverlay extends StatelessWidget {
  const StoreLockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);

    return PopScope(
      canPop: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulsing Lock Icon Badge
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                lang.t(
                  "Store Access Locked",
                  kn: "ಅಂಗಡಿ ಆಕ್ಸೆಸ್ ಲಾಕ್ ಆಗಿದೆ",
                  hi: "स्टोर एक्सेस लॉक है",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                lang.isKannada
                    ? "ನಿಮ್ಮ 30 ದಿನಗಳ ಮೌಲ್ಯಮಾಪನ ಅವಧಿ ಮುಗಿದಿದೆ. ಅಂಗಡಿ ವೈಶಿಷ್ಟ್ಯಗಳನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡಲು ದಯವಿಟ್ಟು ₹49/ತಿಂಗಳ ಚಂದಾದಾರಿಕೆ ಪಾವತಿಸಿ."
                    : (lang.isHindi
                        ? "आपकी 30 दिनों की मूल्यांकन अवधि पूरी हो गई है। सभी सुविधाएं फिर से शुरू करने के लिए कृपया ₹49/माह का भुगतान करें।"
                        : "Your 30-day evaluation period has completed. Please complete payment of ₹49/month to unlock all store features."),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Feature Breakdown Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.point_of_sale_rounded,
                      title: lang.t("Unlimited Fast Billing", kn: "ವೇಗದ ಬಿಲ್ಲಿಂಗ್ ಮತ್ತು ರಶೀದಿ", hi: "तेज़ बिलिंग"),
                    ),
                    const Divider(height: 20),
                    _buildFeatureItem(
                      icon: Icons.menu_book_rounded,
                      title: lang.t("Customer Khata (Digital Ledger)", kn: "ಗ್ರಾಹಕರ ಉದ್ದರಿ ಖಾತೆ", hi: "ग्राहक उधार खाता"),
                    ),
                    const Divider(height: 20),
                    _buildFeatureItem(
                      icon: Icons.inventory_2_rounded,
                      title: lang.t("Live Stock Inventory & Alerts", kn: "ದಾಸ್ತಾನು ನಿರ್ವಹಣೆ", hi: "स्टॉक प्रबंधन"),
                    ),
                    const Divider(height: 20),
                    _buildFeatureItem(
                      icon: Icons.analytics_rounded,
                      title: lang.t("Daily Profit & Sales Analytics", kn: "ದೈನಂದಿನ ಲಾಭ ಲೆಕ್ಕಾಚಾರ", hi: "दैनिक मुनाफ़ा"),
                    ),
                    const Divider(height: 20),
                    _buildFeatureItem(
                      icon: Icons.cloud_done_rounded,
                      title: lang.t("Cloud Backup & WhatsApp Receipts", kn: "ಕ್ಲೌಡ್ ಬ್ಯಾಕಪ್", hi: "क्लाउड बैकअप"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Price Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee_rounded, size: 18, color: AppColors.primary),
                    Text(
                      lang.t("Only ₹49 / Month (₹1.60/day)", kn: "ಕೇವಲ ₹49 / ತಿಂಗಳಿಗೆ", hi: "केवल ₹49 / महीना"),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Primary Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionPaymentScreen()),
                    );
                  },
                  icon: const Icon(Icons.lock_open_rounded, size: 20, color: Colors.white),
                  label: Text(
                    lang.t(
                      "Pay ₹49 & Unlock Store",
                      kn: "₹49 ಪಾವತಿಸಿ ಅನ್‌ಲಾಕ್ ಮಾಡಿ",
                      hi: "₹49 भुगतान करें और अनलॉक करें",
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Instant Test Unlock Simulation (For Demo & Sandbox testing)
              TextButton.icon(
                onPressed: () async {
                  final success = await shopProvider.completeMockPayment();
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang.t(
                            "Store Unlocked Successfully! Active for 30 days.",
                            kn: "ಅಂಗಡಿ ಯಶಸ್ವಿಯಾಗಿ ಅನ್‌ಲಾಕ್ ಆಗಿದೆ! 30 ದಿನಗಳು ಸಕ್ರಿಯವಾಗಿದೆ.",
                            hi: "स्टोर सफलतापूर्वक अनलॉक हो गया! 30 दिनों के लिए सक्रिय।",
                          ),
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                label: Text(
                  lang.t(
                    "Instant Test Unlock (Demo)",
                    kn: "ತಕ್ಷಣ ಅನ್‌ಲಾಕ್ ಪರೀಕ್ಷೆ (ಡೆಮೊ)",
                    hi: "इंस्टेंट टेस्ट अनलॉक (डेमो)",
                  ),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.successDark, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Reminder Banner shown when 14-day free trial has completed (Days 15–29)
class TrialReminderBanner extends StatelessWidget {
  final int daysRemaining;
  const TrialReminderBanner({super.key, required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang.t(
                    "14-Day Free Trial Completed • $daysRemaining Days Left",
                    kn: "14 ದಿನಗಳ ಉಚಿತ ಪ್ರಯೋಗ ಮುಗಿದಿದೆ • $daysRemaining ದಿನಗಳು ಬಾಕಿ",
                    hi: "14 दिनों का फ़्री ट्रायल पूरा हुआ • $daysRemaining दिन शेष",
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lang.isKannada
                ? "ನಿಮ್ಮ 14 ದಿನಗಳ ಉಚಿತ ಪ್ರಯೋಗ ಮುಗಿದಿದೆ. 30ನೇ ದಿನ ಅಂಗಡಿ ಲಾಕ್ ಆಗುವುದನ್ನು ತಪ್ಪಿಸಲು ಈಗಲೇ ₹49/ತಿಂಗಳಿಗೆ ಚಂದಾದಾರರಾಗಿ."
                : (lang.isHindi
                    ? "आपका 14-दिवसीय फ़्री ट्रायल समाप्त हो गया है। 30वें दिन स्टोर लॉक होने से बचाने के लिए अभी ₹49/माह का भुगतान करें।"
                    : "Your 14-day free trial has completed. Subscribe for ₹49/month before day 30 to prevent store lockout."),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78350F),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionPaymentScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.verified_rounded, size: 16),
                label: Text(
                  lang.t("Subscribe for ₹49", kn: "₹49 ಪಾವತಿಸಿ", hi: "₹49 में सब्सक्राइब करें"),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

