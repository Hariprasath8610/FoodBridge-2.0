import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/rescue_model.dart';

class MissionStepper extends StatelessWidget {
  final RescueStatus currentStatus;

  const MissionStepper({
    super.key,
    required this.currentStatus,
  });

  static const List<Map<String, dynamic>> _steps = [
    {'title': 'Requested', 'status': RescueStatus.recipientRequested},
    {'title': 'Approved', 'status': RescueStatus.providerApproved},
    {'title': 'Verified', 'status': RescueStatus.foodVerified},
    {'title': 'In Transit', 'status': RescueStatus.inTransit},
    {'title': 'Delivered', 'status': RescueStatus.delivered},
  ];

  int _getCurrentStepIndex() {
    switch (currentStatus) {
      case RescueStatus.created:
        return -1;
      case RescueStatus.recipientRequested:
        return 0;
      case RescueStatus.providerApproved:
        return 1;
      case RescueStatus.foodVerified:
      case RescueStatus.pickupReady:
        return 2;
      case RescueStatus.pickedUp:
      case RescueStatus.inTransit:
        return 3;
      case RescueStatus.delivered:
        return 4;
      case RescueStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getCurrentStepIndex();

    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line between steps
          final stepIndex = index ~/ 2;
          final isPassed = stepIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 2.5,
              color: isPassed ? AppColors.primary : AppColors.border,
            ),
          );
        } else {
          // Step Node
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < activeIndex;
          final isCurrent = stepIndex == activeIndex;

          Color circleBg;
          Widget icon;

          if (isCompleted) {
            circleBg = AppColors.primary;
            icon = const Icon(Icons.check_rounded, size: 13, color: Colors.white);
          } else if (isCurrent) {
            circleBg = AppColors.primary;
            icon = Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            );
          } else {
            circleBg = AppColors.border;
            icon = Text(
              '${stepIndex + 1}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(height: 6),
              Text(
                _steps[stepIndex]['title'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
