import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class QuantityPicker extends StatelessWidget {
  final double quantity;
  final String unit;
  final ValueChanged<double> onChanged;
  final bool isFractional;

  const QuantityPicker({
    Key? key,
    required this.quantity,
    required this.unit,
    required this.onChanged,
    this.isFractional = true,
  }) : super(key: key);

  void _increment(double delta) {
    final next = double.parse((quantity + delta).toStringAsFixed(3));
    onChanged(next);
  }

  void _decrement(double delta) {
    final next = double.parse((quantity - delta).toStringAsFixed(3));
    if (next >= 0) {
      onChanged(next);
    }
  }

  void _showCustomDialog(BuildContext context) {
    final controller = TextEditingController(text: quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Enter Quantity ($unit)", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: "e.g. 1.250",
            suffixText: unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                onChanged(double.parse(val.toStringAsFixed(3)));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 40),
            ),
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _decrement(isFractional ? (quantity <= 1.0 ? 0.25 : 1.0) : 1.0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.remove, size: 18, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showCustomDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight, width: 1.2),
                ),
                child: Text(
                  "${quantity.toStringAsFixed(isFractional && quantity % 1 != 0 ? 3 : (quantity % 1 == 0 ? 0 : 2))} $unit",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _increment(isFractional ? (quantity < 1.0 ? 0.25 : 1.0) : 1.0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 18, color: AppColors.textWhite),
              ),
            ),
          ],
        ),
        if (isFractional) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              _chipButton("+0.25", () => _increment(0.25)),
              _chipButton("+0.5", () => _increment(0.5)),
              _chipButton("+1", () => _increment(1.0)),
              _chipButton("+5", () => _increment(5.0)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _chipButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
