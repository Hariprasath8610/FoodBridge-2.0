import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/rescue_model.dart';

class MissionStatusBadge extends StatelessWidget {
  final RescueStatus status;
  final bool isCompact;

  const MissionStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case RescueStatus.created:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textSecondary;
        icon = Icons.hourglass_top_rounded;
        break;
      case RescueStatus.recipientRequested:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        icon = Icons.notifications_active_rounded;
        break;
      case RescueStatus.providerApproved:
        bg = const Color(0xFFCCFBF1);
        fg = const Color(0xFF0F766E);
        icon = Icons.check_circle_outline_rounded;
        break;
      case RescueStatus.foodVerified:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        icon = Icons.verified_rounded;
        break;
      case RescueStatus.pickupReady:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        icon = Icons.qr_code_rounded;
        break;
      case RescueStatus.pickedUp:
      case RescueStatus.inTransit:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        icon = Icons.local_shipping_rounded;
        break;
      case RescueStatus.delivered:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        icon = Icons.task_alt_rounded;
        break;
      case RescueStatus.cancelled:
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFBE123C);
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: fg.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.displayName.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
