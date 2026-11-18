import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/shop_categories.dart';
import '../providers/language_provider.dart';
import '../providers/shop_provider.dart';
import '../services/product_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/language_toggle_badge.dart';

class BulkAddProductsScreen extends StatefulWidget {
  const BulkAddProductsScreen({super.key});

  @override
  State<BulkAddProductsScreen> createState() => _BulkAddProductsScreenState();
}

class _BulkAddProductsScreenState extends State<BulkAddProductsScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();

  String? _selectedFileName;
  int? _selectedFileSize;
  Uint8List? _selectedFileBytes;
  String _fileFormat = "excel"; // "excel" or "word"

  bool _isUploading = false;
  bool _isCommitting = false;

  // Parsed results from backend
  List<Map<String, dynamic>> _parsedItems = [];
  Set<int> _selectedIndices = {};
  int _totalRows = 0;
  int _validCount = 0;
  int _invalidCount = 0;

  String _filterMode = "ALL"; // "ALL", "VALID", "INVALID"

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          lang.bulkUploadTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          const LanguageToggleBadge(),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: lang.t("Help", kn: "ಸಹಾಯ", hi: "सहायता"),
            onPressed: _showTemplateGuideDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format Picker Card
                  _buildFormatSelectorCard(lang),
                  const SizedBox(height: 16),

                  // Upload Drop Zone
                  _buildFilePickerSection(lang),
                  const SizedBox(height: 16),

                  // Parse Results & Preview Section
                  if (_parsedItems.isNotEmpty) ...[
                    _buildSummaryStatsSection(),
                    const SizedBox(height: 14),
                    _buildFilterAndSelectBar(),
                    const SizedBox(height: 10),
                    _buildItemsPreviewList(),
                  ] else ...[
                    _buildInstructionsCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _parsedItems.isNotEmpty ? _buildStickyCommitBar() : null,
    );
  }

  Widget _buildFormatSelectorCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
                child: const Icon(Icons.file_copy_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t("Select File Format", kn: "ಫೈಲ್ ಮಾದರಿ ಆಯ್ಕೆಮಾಡಿ", hi: "फ़ाइल प्रकार चुनें"),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    Text(
                      lang.isKannada
                          ? "ಎಕ್ಸೆಲ್ ಅಥವಾ ವರ್ಡ್ ಡಾಕ್ಯುಮೆಂಟ್ ಆಯ್ಕೆಮಾಡಿ"
                          : "Choose Excel sheet or Word document",
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildFormatOptionTile(
                  title: "Excel Sheet",
                  subtitle: ".xlsx, .xls, .csv",
                  icon: Icons.table_chart_rounded,
                  iconColor: const Color(0xFF16A34A),
                  formatKey: "excel",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatOptionTile(
                  title: "Word Document",
                  subtitle: ".docx table / list",
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF2563EB),
                  formatKey: "word",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String formatKey,
  }) {
    final isSelected = _fileFormat == formatKey;
    return InkWell(
      onTap: () {
        setState(() {
          _fileFormat = formatKey;
          _selectedFileName = null;
          _selectedFileBytes = null;
          _parsedItems.clear();
          _selectedIndices.clear();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : iconColor, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerSection(LanguageProvider lang) {
    final hasFile = _selectedFileName != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? AppColors.primary : AppColors.cardBorder,
          style: BorderStyle.solid,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          if (!hasFile) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(
                _fileFormat == "excel" ? Icons.cloud_upload_rounded : Icons.drive_folder_upload_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _fileFormat == "excel"
                  ? lang.t("Select Excel File", kn: "ಎಕ್ಸೆಲ್ ಫೈಲ್ ಆಯ್ಕೆಮಾಡಿ", hi: "एक्सेल फ़ाइल चुनें")
                  : lang.t("Select Word File", kn: "ವರ್ಡ್ ಫೈಲ್ ಆಯ್ಕೆಮಾಡಿ", hi: "वर्ड फ़ाइल चुनें"),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              _fileFormat == "excel"
                  ? (lang.isKannada ? "ವಸ್ತುಗಳ ಪಟ್ಟಿ ಇರುವ ಸ್ಪ್ರೆಡ್‌ಶೀಟ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ" : "Upload spreadsheet containing product rows")
                  : (lang.isKannada ? "ಕೋಷ್ಟಕ ಇರುವ ವರ್ಡ್ ಡಾಕ್ಯುಮೆಂಟ್ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ" : "Upload Word document with product table or list"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            // Primary Action: 1-Tap Load Ready-Made Catalog
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadPreconfiguredCatalog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.bolt_rounded, size: 20, color: Colors.amberAccent),
                label: Text(
                  _fileFormat == "excel"
                      ? (lang.isKannada ? "1-ಕ್ಲಿಕ್ ರೆಡಿ ಎಕ್ಸೆಲ್ ಲಿಸ್ಟ್ (20 ವಸ್ತುಗಳು)" : "1-Tap Load Ready Excel Catalog (20 Items)")
                      : (lang.isKannada ? "1-ಕ್ಲಿಕ್ ರೆಡಿ ವರ್ಡ್ ಲಿಸ್ಟ್ (20 ವಸ್ತುಗಳು)" : "1-Tap Load Ready Word Catalog (20 Items)"),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary Action: Browse file or View Guide
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.primary),
                    label: Text(lang.browseFromPhone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showTemplateGuideDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: Text(lang.t("Guide", kn: "ಸಹಾಯ", hi: "गाइड"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _fileFormat == "excel" ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _fileFormat == "excel" ? Icons.table_chart_rounded : Icons.description_rounded,
                    color: _fileFormat == "excel" ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedFileSize != null ? "${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB" : "",
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.textMuted),
                  tooltip: "Remove file",
                  onPressed: () {
                    setState(() {
                      _selectedFileName = null;
                      _selectedFileBytes = null;
                      _parsedItems.clear();
                      _selectedIndices.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Change File", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadAndParseFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      _isUploading ? "Reading File..." : "Scan & Preview Items",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBadge(
            label: "Total Items",
            value: _totalRows.toString(),
            color: AppColors.textPrimary,
            bgColor: AppColors.surface,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatBadge(
            label: "Ready to Add",
            value: _validCount.toString(),
            color: AppColors.successDark,
            bgColor: AppColors.successLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatBadge(
            label: "Errors / Invalids",
            value: _invalidCount.toString(),
            color: _invalidCount > 0 ? AppColors.debtRedDark : AppColors.textMuted,
            bgColor: _invalidCount > 0 ? AppColors.debtRedLight : AppColors.background,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSelectBar() {
    final allSelected = _selectedIndices.length == _getDisplayItems().length && _selectedIndices.isNotEmpty;
    return Row(
      children: [
        // Select All Checkbox
        InkWell(
          onTap: () {
            setState(() {
              if (allSelected) {
                _selectedIndices.clear();
              } else {
                final display = _getDisplayItems();
                for (int i = 0; i < display.length; i++) {
                  if (display[i]["is_valid"] == true) {
                    _selectedIndices.add(i);
                  }
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              children: [
                Icon(
                  allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                const Text(
                  "Select All",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Filter chips: All, Valid, Errors
        _buildFilterChip("ALL", "All (${_parsedItems.length})"),
        const SizedBox(width: 6),
        _buildFilterChip("VALID", "Valid ($_validCount)"),
        const SizedBox(width: 6),
        _buildFilterChip("INVALID", "Issues ($_invalidCount)"),
      ],
    );
  }

  Widget _buildFilterChip(String mode, String label) {
    final isSelected = _filterMode == mode;
    return InkWell(
      onTap: () => setState(() => _filterMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDisplayItems() {
    if (_filterMode == "VALID") {
      return _parsedItems.where((it) => it["is_valid"] == true).toList();
    } else if (_filterMode == "INVALID") {
      return _parsedItems.where((it) => it["is_valid"] != true).toList();
    }
    return _parsedItems;
  }

  Widget _buildItemsPreviewList() {
    final items = _getDisplayItems();
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          "No products match this filter.",
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isValid = item["is_valid"] == true;
        final isChecked = _selectedIndices.contains(index);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isValid ? (isChecked ? AppColors.primary : AppColors.cardBorder) : AppColors.debtRed,
              width: !isValid || isChecked ? 1.5 : 1,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection checkbox
                Checkbox(
                  value: isChecked,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: isValid
                      ? (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIndices.add(index);
                            } else {
                              _selectedIndices.remove(index);
                            }
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name & Status pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              (item["name"]?.toString().isNotEmpty ?? false)
                                  ? item["name"].toString()
                                  : "Untitled Product (नाम गायब)",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isValid ? AppColors.textPrimary : AppColors.debtRed,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isValid ? AppColors.successLight : AppColors.debtRedLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isValid ? "Ready" : "Error",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isValid ? AppColors.successDark : AppColors.debtRedDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Error message if invalid
                      if (!isValid && item["error_message"] != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.debtRedLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.debtRed),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item["error_message"].toString(),
                                  style: const TextStyle(fontSize: 11, color: AppColors.debtRedDark, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Price & Stock Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildDetailTag(
                            label: "Selling",
                            value: "₹${item['selling_price'] ?? '0'}",
                            isPrimary: true,
                          ),
                          if (item['purchase_price'] != null && double.tryParse(item['purchase_price'].toString()) != 0)
                            _buildDetailTag(
                              label: "Cost",
                              value: "₹${item['purchase_price']}",
                            ),
                          _buildDetailTag(
                            label: "Stock",
                            value: "${item['stock_quantity'] ?? '0'} ${item['unit'] ?? 'pc'}",
                          ),
                          if (item['category'] != null && item['category'] != "General")
                            _buildDetailTag(
                              label: "Category",
                              value: item['category'].toString(),
                            ),
                          if (item['barcode'] != null && item['barcode'].toString().isNotEmpty)
                            _buildDetailTag(
                              label: "Barcode",
                              value: item['barcode'].toString(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailTag({required String label, required String value, bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primarySurface : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isPrimary ? AppColors.primaryLight.withValues(alpha: 0.3) : AppColors.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textMuted)),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.w800, color: isPrimary ? AppColors.primary : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                "How to prepare your file (फ़ाइल कैसे तैयार करें)",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInstructionBullet("1", "Keep column headers in the 1st row: Product Name, Selling Price, Purchase Price, Stock, Unit, Category, Barcode."),
          _buildInstructionBullet("2", "Product Name and Selling Price are mandatory fields (*)."),
          _buildInstructionBullet("3", "Supported units: piece, packet, kg, g, l, ml, box, meter."),
          _buildInstructionBullet("4", "Word (.docx) files can contain a table or bulleted list."),
        ],
      ),
    );
  }

  Widget _buildInstructionBullet(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            alignment: Alignment.center,
            child: Text(num, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCommitBar() {
    final count = _selectedIndices.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: AppColors.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count Selected",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                ),
                Text(
                  "Out of $_validCount valid items",
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: _isCommitting ? "Importing..." : "Add to Inventory ($count सामान)",
                isLoading: _isCommitting,
                onPressed: count == 0 || _isCommitting ? null : _commitSelectedItems,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadPreconfiguredCatalog() {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final categoryId = shopProvider.shop?.category ?? ShopCategories.provisionStore;
    final catInfo = ShopCategories.getCategoryById(categoryId);

    final List<Map<String, dynamic>> items = catInfo.catalogPresets.map((p) {
      return {
        "name": p.name,
        "selling_price": p.defaultSellingPrice,
        "purchase_price": p.defaultPurchasePrice,
        "stock": p.defaultStock,
        "unit": p.defaultUnit,
        "category": p.defaultCategory,
        "barcode": null,
        "is_valid": true,
        "error_message": null,
      };
    }).toList();

    final Set<int> validIndices = {for (int i = 0; i < items.length; i++) i};

    setState(() {
      _selectedFileName = _fileFormat == "excel"
          ? "${catInfo.englishName.replaceAll(' ', '_')}_Excel_Catalog.xlsx"
          : "${catInfo.englishName.replaceAll(' ', '_')}_Word_Catalog.docx";
      _selectedFileSize = items.length * 128;
      _parsedItems = items;
      _selectedIndices = validIndices;
      _totalRows = items.length;
      _validCount = items.length;
      _invalidCount = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Loaded ${items.length} popular items from ${catInfo.englishName} catalog!"),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final allowedExtensions = _fileFormat == "excel" ? ['xlsx', 'xls', 'csv'] : ['docx', 'doc'];
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result.isNotEmpty) {
        final file = result.first;
        final name = file.name.toLowerCase();
        final isValidExt = allowedExtensions.any((ext) => name.endsWith(".$ext"));
        if (!isValidExt) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Please select a valid ${_fileFormat == 'excel' ? 'Excel (.xlsx, .csv)' : 'Word (.docx)'} file.",
              ),
              backgroundColor: AppColors.debtRed,
            ),
          );
          return;
        }

        final bytes = await file.readAsBytes();

        if (bytes.isNotEmpty) {
          setState(() {
            _selectedFileName = file.name;
            _selectedFileSize = bytes.length;
            _selectedFileBytes = bytes;
            _parsedItems.clear();
            _selectedIndices.clear();
          });
          // Auto-trigger parse
          _uploadAndParseFile();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e"), backgroundColor: AppColors.debtRed),
      );
    }
  }

  Future<void> _uploadAndParseFile() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    setState(() => _isUploading = true);
    try {
      final response = await _productService.uploadBulkProductFile(
        _selectedFileBytes!,
        _selectedFileName!,
      );

      final itemsRaw = (response["items"] as List<dynamic>?) ?? [];
      final List<Map<String, dynamic>> items = itemsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final Set<int> validIndices = {};
      for (int i = 0; i < items.length; i++) {
        if (items[i]["is_valid"] == true) {
          validIndices.add(i);
        }
      }

      if (!mounted) return;
      setState(() {
        _parsedItems = items;
        _selectedIndices = validIndices;
        _totalRows = response["total_rows"] ?? items.length;
        _validCount = response["valid_count"] ?? validIndices.length;
        _invalidCount = response["invalid_count"] ?? (items.length - validIndices.length);
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Parsed ${items.length} items (${validIndices.length} ready to add)"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to parse file: $e"), backgroundColor: AppColors.debtRed),
      );
    }
  }

  Future<void> _commitSelectedItems() async {
    final selectedItems = _selectedIndices.map((i) => _parsedItems[i]).toList();
    if (selectedItems.isEmpty) return;

    setState(() => _isCommitting = true);
    try {
      final response = await _productService.commitBulkProducts(selectedItems);
      final count = response["imported_count"] ?? selectedItems.length;

      if (!mounted) return;
      setState(() => _isCommitting = false);

      // Show celebratory confirmation
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                "Products Added!",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                "Successfully added $count products to your shop catalog.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Back to Products",
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, true); // return to product list with refresh flag
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCommitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to import products: $e"), backgroundColor: AppColors.debtRed),
      );
    }
  }

  void _showTemplateGuideDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_view_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  "Template Columns Guide",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            _buildColumnDescRow("Product Name *", "Item name (e.g. Tata Salt 1kg, Aashirvaad Atta 5kg)", isMandatory: true),
            _buildColumnDescRow("Selling Price *", "Customer price in ₹ (e.g. 28.00)", isMandatory: true),
            _buildColumnDescRow("Purchase Price", "Your purchase/cost price in ₹ (e.g. 23.50)"),
            _buildColumnDescRow("Stock Qty", "Initial stock count (e.g. 50)"),
            _buildColumnDescRow("Unit", "piece, packet, kg, g, l, ml, box"),
            _buildColumnDescRow("Category", "Groceries, Snacks, Dairy, etc."),
            _buildColumnDescRow("Barcode", "12-13 digit scanner barcode (optional)"),
            const SizedBox(height: 16),
            const Text(
              "Both Excel (.xlsx) and Word (.docx table) files work seamlessly.",
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnDescRow(String col, String desc, {bool isMandatory = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              col,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isMandatory ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
