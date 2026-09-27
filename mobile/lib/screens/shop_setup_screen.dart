import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/shop_categories.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/upi_qr_helper.dart';
import 'subscription_screen.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({Key? key}) : super(key: key);

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _upiIdController = TextEditingController();

  String _selectedCategory = ShopCategories.provisionStore;
  String? _upiQrImage;

  String get _shopNameHint {
    switch (_selectedCategory) {
      case ShopCategories.electrical:
        return "e.g. Sharma Electricals & Appliances";
      case ShopCategories.furniture:
        return "e.g. Royal Furniture Mart";
      case ShopCategories.riceRetail:
        return "e.g. Sri Balaji Rice & Grain Depot";
      case ShopCategories.clothing:
        return "e.g. Classic Garments & Cloth Store";
      case ShopCategories.hardware:
        return "e.g. National Hardware & Sanitary";
      case ShopCategories.pharmacy:
        return "e.g. Sanjeevani Medical & Pharmacy";
      case ShopCategories.generalStore:
        return "e.g. Anand General Store";
      case ShopCategories.provisionStore:
      default:
        return "e.g. Radhe Krishna Kirana Store";
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _pickQrImage() async {
    final result = await UpiQrHelper.showQrPickerSheet(
      context,
      currentUpiId: _upiIdController.text.trim().isEmpty ? null : _upiIdController.text.trim(),
      currentImage: _upiQrImage,
    );

    if (result != null) {
      setState(() {
        _upiQrImage = result['upi_qr_image'];
        if (result['upi_id'] != null && result['upi_id']!.isNotEmpty) {
          _upiIdController.text = result['upi_id']!;
        }
      });
    }
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await shopProvider.setupShop(
      shopName: _shopNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      category: _selectedCategory,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      upiQrImage: _upiQrImage,
      upiId: _upiIdController.text.trim().isEmpty ? null : _upiIdController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.errorMessage ?? "Failed to save shop profile"),
          backgroundColor: AppColors.debtRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (shopProvider.shop != null) {
      authProvider.setShop(shopProvider.shop!);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final selectedCatInfo = ShopCategories.getCategoryById(_selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Store Profile Setup",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Enter store details once. They will automatically appear on customer bills and WhatsApp receipts.",
                          style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Shop Category Card (Prominently at the top)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selectedCatInfo.themeColor.withValues(alpha: 0.35), width: 1.5),
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
                              color: selectedCatInfo.themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(selectedCatInfo.icon, color: selectedCatInfo.themeColor, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Shop Category (दुकान की श्रेणी) *",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Select your shop type to auto-configure products",
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: AppColors.primarySurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        items: ShopCategories.categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.themeColor, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.displayName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      // Quick Category Chips
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ShopCategories.categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final cat = ShopCategories.categories[index];
                            final isSelected = cat.id == _selectedCategory;
                            return ChoiceChip(
                              avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.themeColor),
                              label: Text(
                                cat.englishName,
                                style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                              ),
                              selected: isSelected,
                              selectedColor: cat.themeColor,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                              onSelected: (_) => setState(() => _selectedCategory = cat.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Auto-catalogs your 'Add Product' screen with ${selectedCatInfo.englishName} items.",
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Shop Name & Owner Name
                CustomTextField(
                  label: "Shop Name (दुकान का नाम) *",
                  hint: _shopNameHint,
                  controller: _shopNameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Store name is required" : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Owner Name (दुकानदार का नाम) *",
                  hint: "e.g. Satish Sharma",
                  controller: _ownerNameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Owner name is required" : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Store Address (पता)",
                  hint: "Shop No. 12, Main Market",
                  controller: _addressController,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: "City (शहर)",
                        hint: "e.g. Pune, Jaipur",
                        controller: _cityController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: "State (राज्य)",
                        hint: "e.g. Maharashtra",
                        controller: _stateController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Pincode (पिनकोड)",
                  hint: "6-digit PIN (e.g. 411001)",
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Optional UPI QR Upload Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.upiPurple.withValues(alpha: 0.3), width: 1.2),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded, color: AppColors.upiPurple, size: 24),
                          SizedBox(width: 8),
                          Text(
                            "UPI Scanner Screenshot (वैकल्पिक / Optional)",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.upiPurpleLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: AppColors.upiPurple, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Tip: Take a screenshot of your Google Pay, PhonePe, or Paytm QR standee and upload here so customers can scan it directly during billing.",
                                style: TextStyle(fontSize: 11, color: AppColors.upiPurple, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_upiQrImage != null) ...[
                        Center(
                          child: Stack(
                            children: [
                              UpiQrHelper.buildQrImageWidget(_upiQrImage, height: 160),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: InkWell(
                                  onTap: () => setState(() => _upiQrImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.debtRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickQrImage,
                              icon: Icon(_upiQrImage != null ? Icons.edit : Icons.upload_file, size: 18),
                              label: Text(_upiQrImage != null ? "Change Screenshot" : "Upload QR Screenshot"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.upiPurple,
                                side: const BorderSide(color: AppColors.upiPurple),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: "UPI ID (वैकल्पिक)",
                        hint: "उदा. sharma@okaxis",
                        controller: _upiIdController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: "Save & Continue (आगे बढ़ें)",
                  isLoading: shopProvider.isLoading,
                  onPressed: _handleSetup,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
