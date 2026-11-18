import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';
import 'sales_history_screen.dart';
import 'inventory_screen.dart';
import 'welcome_screen.dart';
import 'legal_screen.dart';
import '../core/constants/legal_content.dart';
import '../providers/language_provider.dart';
import '../widgets/language_toggle_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Server API URL"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Emulator: http://10.0.2.2:8000/api\nPhysical device: http://YOUR_PC_IP:8000/api",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Base URL"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ApiConstants.baseUrl = controller.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("API base set to: ${ApiConstants.baseUrl}")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context, AuthProvider auth) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.debtRed, size: 24),
            const SizedBox(width: 8),
            Text(lang.deleteAccountLabel),
          ],
        ),
        content: const Text(
          "Are you sure you want to permanently delete your user account and all shop data?\n\n"
          "• Store profile, products, sales and khata records will be completely deleted.\n"
          "• You can register again anytime using the same mobile number or email.",
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.debtRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete Permanently"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await auth.deleteAccount();
      if (!context.mounted) return;
      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account and shop data deleted. You can register again anytime."),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? "Failed to delete account"),
            backgroundColor: AppColors.debtRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.settingsTitle),
        actions: const [
          LanguageToggleBadge(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Preference Card
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isKannada ? "App Language (ಭಾಷಾ ಆಯ್ಕೆ)" : "App Language (भाषा चयन)",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            "Active: ${lang.currentDisplayName}",
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const LanguageToggleBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => lang.setLanguage(LanguageMode.kannada),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: lang.isKannada ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: lang.isKannada ? AppColors.primary : AppColors.cardBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "English (ಕನ್ನಡ)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: lang.isKannada ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => lang.setLanguage(LanguageMode.hindi),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: lang.isHindi ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: lang.isHindi ? AppColors.primary : AppColors.cardBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "English (हिंदी)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: lang.isHindi ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _menuTile(
            icon: Icons.store_rounded,
            title: "Store & Owner Profile",
            subtitle: "Shop name, address, phone number",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _menuTile(
            icon: Icons.receipt_long_rounded,
            title: "Sales History & Receipts",
            subtitle: "View, filter and reprint past bills",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
              );
            },
          ),
          _menuTile(
            icon: Icons.inventory_2_rounded,
            title: "Inventory & Stock Audit",
            subtitle: "Stock movements, restock & adjustment",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              );
            },
          ),
          _menuTile(
            icon: Icons.workspace_premium_rounded,
            title: "Retailza Subscription",
            subtitle: "₹49/month Kirana SaaS Plan status & renewal",
            iconColor: Colors.amber.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            lang.t("Legal & Compliance", kn: "ನಿಯಮಗಳು ಮತ್ತು ನೀತಿಗಳು", hi: "नीतियां और कॉपीराइट"),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "Data protection and privacy commitments",
            iconColor: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LegalScreen(initialTabIndex: 0)),
              );
            },
          ),
          _menuTile(
            icon: Icons.gavel_rounded,
            title: "Terms & Conditions",
            subtitle: "Merchant service agreement and usage terms",
            iconColor: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LegalScreen(initialTabIndex: 1)),
              );
            },
          ),
          _menuTile(
            icon: Icons.copyright_rounded,
            title: "Copyright & About",
            subtitle: "TechMasters Innovations Private Limited",
            iconColor: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LegalScreen(initialTabIndex: 2)),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text("Developer & Network", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _menuTile(
            icon: Icons.wifi,
            title: "API Server Connection",
            subtitle: ApiConstants.baseUrl,
            onTap: () => _showServerConfigDialog(context),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.debtRed,
              side: const BorderSide(color: AppColors.debtRed),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(lang.logoutLabel),
                  content: const Text("Are you sure you want to log out of Retailza?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.debtRed),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(lang.logoutLabel),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.debtRed,
            ),
            onPressed: () => _handleDeleteAccount(context, auth),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: Text(
              lang.t("Delete Account & Shop Data", kn: "ಖಾತೆ ಮತ್ತು ಅಂಗಡಿ ಡೇಟಾ ಅಳಿಸಿ", hi: "खाता और दुकान डेटा हटाएं"),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: const [
                Text(
                  "Retailza Version 1.0.0 (Commercial Production)",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                SizedBox(height: 3),
                Text(
                  "A product of TechMasters Innovations Private Limited",
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                SizedBox(height: 3),
                Text(
                  LegalContent.copyrightNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
