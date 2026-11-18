import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/language_provider.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMode; // 'CASH', 'UPI', 'CREDIT'
  final ValueChanged<String> onSelected;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMode,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Row(
      children: [
        Expanded(
          child: _buildOption(
            title: lang.cashTitle,
            mode: "CASH",
            icon: Icons.payments_rounded,
            activeColor: AppColors.success,
            activeBg: AppColors.successLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOption(
            title: lang.upiTitle,
            mode: "UPI",
            icon: Icons.qr_code_2_rounded,
            activeColor: AppColors.upiPurple,
            activeBg: AppColors.upiPurpleLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildOption(
            title: lang.khataTitle,
            mode: "CREDIT",
            icon: Icons.menu_book_rounded,
            activeColor: AppColors.debtRed,
            activeBg: AppColors.debtRedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required String title,
    required String mode,
    required IconData icon,
    required Color activeColor,
    required Color activeBg,
  }) {
    final bool isSelected = selectedMode == mode;

    return InkWell(
      onTap: () => onSelected(mode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppColors.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : AppColors.textSecondary, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
