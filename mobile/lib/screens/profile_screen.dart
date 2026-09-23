import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import 'subscription_screen.dart';
import 'legal_screen.dart';
import 'welcome_screen.dart';
import '../core/constants/legal_content.dart';
import '../widgets/upi_qr_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _manageUpiQr(BuildContext context, ShopProvider shopProvider) async {
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
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("UPI QR settings updated successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showEditShopDialog(BuildContext context, ShopProvider shopProvider, AuthProvider authProvider) async {
    final s = shopProvider.shop ?? authProvider.shop;
    final shopNameCtrl = TextEditingController(text: s?.shopName ?? "");
    final ownerNameCtrl = TextEditingController(text: s?.ownerName ?? "");
    final addressCtrl = TextEditingController(text: s?.address ?? "");
    final cityCtrl = TextEditingController(text: s?.city ?? "");
    final stateCtrl = TextEditingController(text: s?.state ?? "");
    final pincodeCtrl = TextEditingController(text: s?.pincode ?? "");

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Edit Store Profile",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: shopNameCtrl,
                  decoration: const InputDecoration(labelText: "Store Name *"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerNameCtrl,
                  decoration: const InputDecoration(labelText: "Owner Name *"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: "Store Address"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(labelText: "City (शहर)"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stateCtrl,
                        decoration: const InputDecoration(labelText: "State (राज्य)"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pincodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Pincode (पिनकोड)"),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (shopNameCtrl.text.trim().isEmpty || ownerNameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Shop and Owner names are required")),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      final success = await shopProvider.updateShop(
                        shopName: shopNameCtrl.text.trim(),
                        ownerName: ownerNameCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        state: stateCtrl.text.trim(),
                        pincode: pincodeCtrl.text.trim(),
                      );
                      if (success && shopProvider.shop != null) {
                        authProvider.setShop(shopProvider.shop!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Store details updated successfully!"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final shop = Provider.of<ShopProvider>(context);

    final s = shop.shop ?? auth.shop;
    final u = auth.user;
    final hasQrImage = s?.upiQrImage != null && s!.upiQrImage!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Store & Owner Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.storefront, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s?.shopName ?? "Kirana Store",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Owner: ${s?.ownerName ?? u?.name ?? 'Shopkeeper'}",
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subscription Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: shop.isSubscriptionActive ? AppColors.successLight : AppColors.debtRedLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: shop.isSubscriptionActive ? AppColors.success : AppColors.debtRed,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    shop.isSubscriptionActive ? Icons.verified_rounded : Icons.error_outline_rounded,
                    color: shop.isSubscriptionActive ? AppColors.success : AppColors.debtRed,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.isSubscriptionActive ? "Retailza Pro: ACTIVE" : "Retailza Pro: EXPIRED",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: shop.isSubscriptionActive ? AppColors.success : AppColors.debtRed,
                          ),
                        ),
                        Text(
                          shop.isSubscriptionActive ? "₹49/month • All features unlocked" : "Renew subscription for ₹49/month",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                      );
                    },
                    child: Text(shop.isSubscriptionActive ? "Manage" : "Renew"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // UPI Scanner QR Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.upiPurple.withOpacity(0.3), width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.qr_code_2_rounded, color: AppColors.upiPurple, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Store UPI Scanner QR",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _manageUpiQr(context, shop),
                        icon: Icon(hasQrImage ? Icons.edit : Icons.upload_file, size: 16),
                        label: Text(hasQrImage ? "Update" : "Upload"),
                        style: TextButton.styleFrom(foregroundColor: AppColors.upiPurple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (hasQrImage) ...[
                    Center(child: UpiQrHelper.buildQrImageWidget(s.upiQrImage, height: 160)),
                    const SizedBox(height: 10),
                    if (s.upiId != null && s.upiId!.isNotEmpty) ...[
                      Text(
                        "UPI ID: ${s.upiId}",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.upiPurple),
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Text(
                      "This QR code is shown to customers when they pay via UPI.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.upiPurpleLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.upiPurple, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "No UPI QR uploaded yet. Upload your screenshot so customers can scan directly from your phone.",
                              style: TextStyle(fontSize: 12, color: AppColors.upiPurple),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Store Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Store Details",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showEditShopDialog(context, shop, auth),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                        label: const Text("Edit", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  _infoTile("Phone Number", u?.mobileNumber != null ? "+91 ${u!.mobileNumber}" : "Not set"),
                  const Divider(height: 18),
                  _infoTile("Address", (s?.address != null && s!.address!.trim().isNotEmpty) ? s.address! : "Not specified"),
                  const Divider(height: 18),
                  _infoTile(
                    "City & State",
                    [
                      if (s?.city != null && s!.city!.trim().isNotEmpty) s.city!.trim(),
                      if (s?.state != null && s!.state!.trim().isNotEmpty) s.state!.trim(),
                    ].isNotEmpty
                        ? [
                            if (s?.city != null && s!.city!.trim().isNotEmpty) s.city!.trim(),
                            if (s?.state != null && s!.state!.trim().isNotEmpty) s.state!.trim(),
                          ].join(', ')
                        : "Not specified",
                  ),
                  const Divider(height: 18),
                  _infoTile("Pincode", (s?.pincode != null && s!.pincode!.trim().isNotEmpty) ? s.pincode! : "Not specified"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Legal & Compliance Button
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              tileColor: AppColors.surface,
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text("Legal Policies & Compliance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Privacy Policy, Terms & Copyright", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalScreen()),
                );
              },
            ),
            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.debtRed,
                  side: const BorderSide(color: AppColors.debtRed, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                label: const Text("Logout (लॉग आउट करें)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),

            // Company & Copyright Footer
            Center(
              child: Column(
                children: const [
                  Text(
                    "Retailza by ${LegalContent.companyName}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
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
      ),
    );
  }

  Widget _infoTile(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
