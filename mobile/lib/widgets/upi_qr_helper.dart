import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';

class UpiQrHelper {
  // A clean, sample SVG-like base64 Kirana QR for instant testing if on emulator or web
  static const String sampleQrBase64 =
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAADICAYAAACtWK6eAAAACXBIWXMAAAsTAAALEwEAmpwYAAA"
      "BtsURBVHic7dxBDcAgEARAx0lABpYQ1m8C0lOD/Vpme8676d1n2w9e1x/A1/wB6HMAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6"
      "HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6H"
      "IAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HI"
      "McB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHoc"
      "QB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocg"
      "B4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIMcB6HEAehyAHgcgxwHocQB6HIAeByDHAehxAHocgB4HIEcD7g5q4R4Yq0MA"
      "AAAASUVORK5CYII=";

  static Uint8List? decodeBase64Image(String? base64Str) {
    if (base64Str == null || base64Str.trim().isEmpty) return null;
    try {
      String cleanStr = base64Str.trim();
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',').last;
      }
      return base64Decode(cleanStr);
    } catch (_) {
      return null;
    }
  }

  static Widget buildQrImageWidget(String? base64Str, {double height = 220}) {
    final bytes = decodeBase64Image(base64Str);
    if (bytes != null && bytes.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.upiPurple.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.upiPurple.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            height: height,
            width: height,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildFallbackQr(height),
          ),
        ),
      );
    }
    return _buildFallbackQr(height);
  }

  static Widget _buildFallbackQr(double height) {
    return Container(
      height: height,
      width: height,
      decoration: BoxDecoration(
        color: AppColors.upiPurpleLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.upiPurple, width: 1.5),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 80, color: AppColors.upiPurple),
          SizedBox(height: 8),
          Text(
            "Scan to Pay via UPI",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.upiPurple),
          ),
        ],
      ),
    );
  }

  static Future<Map<String, String?>?> showQrPickerSheet(
    BuildContext context, {
    String? currentUpiId,
    String? currentImage,
  }) async {
    final upiIdController = TextEditingController(text: currentUpiId ?? "");
    String? selectedBase64 = currentImage;

    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final XFile? file = await picker.pickImage(source: source, imageQuality: 85);
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  final b64 = "data:image/png;base64,${base64Encode(bytes)}";
                  setModalState(() {
                    selectedBase64 = b64;
                  });
                }
              } catch (e) {
                if (modalCtx.mounted) {
                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                    SnackBar(content: Text("Could not access image: $e")),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Store UPI Scanner (QR कोड)",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.upiPurpleLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.screenshot_outlined, color: AppColors.upiPurple, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Take a screenshot of your Google Pay, PhonePe, or Paytm QR code and upload it here.",
                              style: TextStyle(fontSize: 12, color: AppColors.upiPurple, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preview if selected
                    if (selectedBase64 != null) ...[
                      Center(
                        child: Stack(
                          children: [
                            buildQrImageWidget(selectedBase64, height: 160),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () => setModalState(() => selectedBase64 = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.debtRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text("Gallery (गैलरी)", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.upiPurple,
                              side: const BorderSide(color: AppColors.upiPurple),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text("Camera (कैमरा)", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            selectedBase64 = sampleQrBase64;
                          });
                        },
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: const Text("Use Sample Test QR (सैंपल क्यूआर)", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const Divider(height: 24),

                    // UPI ID Field
                    TextField(
                      controller: upiIdController,
                      decoration: const InputDecoration(
                        labelText: "UPI ID (उदा. sharma@okaxis / 9876543210@paytm)",
                        prefixIcon: Icon(Icons.alternate_email, color: AppColors.upiPurple),
                        hintText: "optional",
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx, {
                          'upi_qr_image': selectedBase64,
                          'upi_id': upiIdController.text.trim().isEmpty ? null : upiIdController.text.trim(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Save QR Details (सुरक्षित करें)", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
