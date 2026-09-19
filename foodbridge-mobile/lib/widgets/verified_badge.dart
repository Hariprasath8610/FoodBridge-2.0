import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum VerifiedType { provider, recipient, general }

class VerifiedBadge extends StatelessWidget {
  final String? label;
  final VerifiedType type;
  final bool isCompact;

  const VerifiedBadge({
    super.key,
    this.label,
    this.type = VerifiedType.general,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color bgColor;
    Color textColor;
    String displayLabel = label ?? 'VERIFIED';

    switch (type) {
      case VerifiedType.provider:
        iconColor = AppColors.primary;
        bgColor = const Color(0xFFF0FDF4); // Subtle mint tint
        textColor = const Color(0xFF166534);
        displayLabel = label ?? 'VERIFIED PROVIDER';
        break;
      case VerifiedType.recipient:
        iconColor = const Color(0xFF0284C7); // Trustworthy blue
        bgColor = const Color(0xFFF0F9FF);
        textColor = const Color(0xFF0369A1);
        displayLabel = label ?? 'VERIFIED RECIPIENT';
        break;
      case VerifiedType.general:
        iconColor = AppColors.primary;
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF166534);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: iconColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: isCompact ? 11 : 13,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            displayLabel.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 9 : 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
