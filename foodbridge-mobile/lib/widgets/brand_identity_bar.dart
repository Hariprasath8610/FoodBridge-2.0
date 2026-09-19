import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BrandIdentityBar extends StatelessWidget {
  final int? activeStepIndex; // 0: Predict, 1: Match, 2: Rescue, 3: Impact
  final bool isCompact;

  const BrandIdentityBar({
    super.key,
    this.activeStepIndex,
    this.isCompact = false,
  });

  static const List<Map<String, dynamic>> _steps = [
    {'title': 'Predict', 'icon': Icons.insights_rounded},
    {'title': 'Match', 'icon': Icons.hub_rounded},
    {'title': 'Rescue', 'icon': Icons.local_shipping_rounded},
    {'title': 'Impact', 'icon': Icons.eco_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Arrow separator
            return Icon(
              Icons.arrow_forward_ios_rounded,
              size: isCompact ? 9 : 11,
              color: AppColors.textLight.withOpacity(0.6),
            );
          }

          final stepIndex = index ~/ 2;
          final step = _steps[stepIndex];
          final isActive = activeStepIndex == stepIndex;
          final isPast = activeStepIndex != null && activeStepIndex! > stepIndex;

          Color color;
          FontWeight weight;
          if (isActive) {
            color = AppColors.primary;
            weight = FontWeight.w700;
          } else if (isPast) {
            color = AppColors.textPrimary;
            weight = FontWeight.w600;
          } else {
            color = AppColors.textSecondary;
            weight = FontWeight.w500;
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                step['icon'] as IconData,
                size: isCompact ? 12 : 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                step['title'] as String,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: weight,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
