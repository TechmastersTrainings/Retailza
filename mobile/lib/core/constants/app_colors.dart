import 'package:flutter/material.dart';

class AppColors {
  // Executive Warm Sand & Terracotta Primary Palette
  static const Color primary = Color(0xFFC2410C);        // Spiced Terracotta
  static const Color primaryDark = Color(0xFF9A3412);    // Deep Terracotta
  static const Color primaryLight = Color(0xFFEA580C);   // Warm Amber Terracotta
  static const Color primaryAccent = Color(0xFFD97706);  // Golden Amber Accent
  static const Color primarySurface = Color(0xFFFFF7ED); // Soft Warm Linen/Terracotta Tint

  // Financial & Operational Indicators
  static const Color success = Color(0xFF15803D);        // Sage Emerald (Paid / Profit)
  static const Color successDark = Color(0xFF166534);    // Deep Sage Green
  static const Color successLight = Color(0xFFDCFCE7);   // Soft Sage Surface

  static const Color debtRed = Color(0xFFDC2626);        // Crimson (Khata / Debt Due)
  static const Color debtRedDark = Color(0xFF991B1B);    // Deep Crimson
  static const Color debtRedLight = Color(0xFFFEE2E2);   // Soft Crimson Tint

  static const Color warning = Color(0xFFD97706);        // Golden Amber (Low Stock / Alerts)
  static const Color warningDark = Color(0xFFB45309);    // Deep Amber
  static const Color warningLight = Color(0xFFFEF3C7);   // Soft Amber Cream Tint

  static const Color upiPurple = Color(0xFFC2410C);      // Terracotta Accent for UPI
  static const Color upiPurpleDark = Color(0xFF9A3412);  // Deep Accent
  static const Color upiPurpleLight = Color(0xFFFFEDD5); // Soft Terracotta Tint

  // Background, Surface & Borders (Warm Sand & Linen Porcelain)
  static const Color background = Color(0xFFF8F6F0);     // Warm Linen Base
  static const Color surface = Color(0xFFFFFFFF);        // Pure Porcelain White
  static const Color cardBorder = Color(0xFFE7E0D4);     // Subtle Stone Linen Border
  static const Color cardBorderFocus = Color(0xFFC2410C);// Terracotta Border

  // Typography Colors (Espresso & Stone)
  static const Color textPrimary = Color(0xFF1C1917);    // Deep Espresso High Contrast
  static const Color textSecondary = Color(0xFF44403C);  // Warm Stone Body Text
  static const Color textMuted = Color(0xFF78716C);      // Stone Muted
  static const Color textWhite = Color(0xFFFFFFFF);

  // Input & Dividers
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEDE7DC);

  // Reusable Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9A3412), Color(0xFFC2410C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF166534), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient khataGradient = LinearGradient(
    colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient upiGradient = LinearGradient(
    colors: [Color(0xFF9A3412), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF292524), Color(0xFF1C1917)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Layered Box Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF554B41).withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF554B41).withValues(alpha: 0.07),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF554B41).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get glowPrimary => [
    BoxShadow(
      color: primary.withValues(alpha: 0.24),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];
}
