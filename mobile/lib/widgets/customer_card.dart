import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback? onSettle;

  const CustomerCard({
    Key? key,
    required this.customer,
    required this.onTap,
    this.onSettle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasDebt = customer.balance > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDebt ? AppColors.debtRed.withValues(alpha: 0.25) : AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: hasDebt ? AppColors.debtRedLight : AppColors.successLight,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "C",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: hasDebt ? AppColors.debtRed : AppColors.successDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 13,
                            color: customer.mobileNumber != null && customer.mobileNumber!.isNotEmpty
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer.mobileNumber != null && customer.mobileNumber!.isNotEmpty
                                ? "+91 ${customer.mobileNumber}"
                                : "No phone saved",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hasDebt ? "₹${customer.balance.toStringAsFixed(2)}" : "₹0.00",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: hasDebt ? AppColors.debtRed : AppColors.successDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasDebt ? AppColors.debtRedLight : AppColors.successLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasDebt ? "Due (बाकी)" : "Settled (चुका दिया)",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: hasDebt ? AppColors.debtRed : AppColors.successDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
