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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings & Store (सेटिंग्स)"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const Text(
            "Legal & Compliance (नीतियां और कॉपीराइट)",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
                  title: const Text("Logout (लॉग आउट)"),
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
            label: const Text("Logout (लॉग आउट करें)"),
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
