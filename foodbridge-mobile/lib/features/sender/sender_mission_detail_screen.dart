import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rescue_model.dart';
import '../../services/rescue_service.dart';
import '../../widgets/brand_identity_bar.dart';
import '../../widgets/error_state_card.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/mission_status_badge.dart';
import '../../widgets/mission_stepper.dart';
import '../../widgets/verified_badge.dart';

class SenderMissionDetailScreen extends ConsumerStatefulWidget {
  final String missionId;

  const SenderMissionDetailScreen({
    super.key,
    required this.missionId,
  });

  @override
  ConsumerState<SenderMissionDetailScreen> createState() =>
      _SenderMissionDetailScreenState();
}

class _SenderMissionDetailScreenState
    extends ConsumerState<SenderMissionDetailScreen> {
  late Future<RescueMission> _missionFuture;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  void _loadMission() {
    _missionFuture =
        ref.read(rescueServiceProvider).getRescue(widget.missionId);
  }

  Future<void> _approveMission() async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(rescueServiceProvider).approveRescue(widget.missionId);
      ref.invalidate(activeRescuesProvider);
      setState(() {
        _isActionInProgress = false;
        _loadMission();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Rescue approved! Proceed to food safety certification.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rescue Mission Control'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _loadMission()),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: FutureBuilder<RescueMission>(
        future: _missionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isActionInProgress) {
            return const LoadingStateView(
              message: 'Loading mission details...',
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ErrorStateCard(
                  title: 'Mission Not Found',
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() => _loadMission()),
                ),
              ),
            );
          }

          final mission = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // FoodBridge Pipeline Bar (Rescue Active)
                const BrandIdentityBar(activeStepIndex: 2),
                const SizedBox(height: 16),

                // Mission Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MISSION TRACKING CODE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mission.rescueCode,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          MissionStatusBadge(status: mission.status),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'RECIPIENT COMMUNITY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        mission.recipientName ??
                                            'Hope Community Kitchen',
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(
                                      type: VerifiedType.recipient,
                                      isCompact: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'QUANTITY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${mission.quantity.toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '~ ${(mission.quantity * 2).round()} Meals',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Lifecycle Stepper
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESCUE LIFECYCLE PROGRESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      MissionStepper(currentStatus: mission.status),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Contextual Primary Action Section
                _buildActionSection(context, mission),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, RescueMission mission) {
    if (mission.status == RescueStatus.recipientRequested) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notification_important_rounded,
                    color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Text(
                  'RECIPIENT REQUEST PENDING',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${mission.recipientName ?? "The community recipient"} has requested to claim this food surplus allocation. Approve to proceed with safety checks.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _approveMission,
              child: const Text('Approve Rescue Mission'),
            ),
          ],
        ),
      );
    }

    if (mission.status == RescueStatus.providerApproved) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.health_and_safety_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'FOOD SAFETY AUDIT REQUIRED',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete the food hygiene, temperature, and safe packaging checklist before vehicle pickup.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final verified = await context.push<bool>(
                  '/sender/mission/${mission.id}/verify-food',
                );
                if (verified == true) {
                  _loadMission();
                }
              },
              icon: const Icon(Icons.verified_user_rounded, size: 18),
              label: const Text('Certify Food Safety'),
            ),
          ],
        ),
      );
    }

    if (mission.status == RescueStatus.foodVerified ||
        mission.status == RescueStatus.pickupReady) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.qr_code_2_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'DRIVER PICKUP READY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Food is safety-certified and packaged. Show the pickup QR or verify the recipient driver\'s OTP.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final completed = await context.push<bool>(
                  '/sender/mission/${mission.id}/pickup',
                  extra: mission,
                );
                if (completed == true) {
                  _loadMission();
                }
              },
              icon: const Icon(Icons.qr_code_rounded, size: 18),
              label: const Text('Verify Vehicle Pickup (QR / OTP)'),
            ),
          ],
        ),
      );
    }

    if (mission.status == RescueStatus.inTransit ||
        mission.status == RescueStatus.pickedUp) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6D28D9).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Color(0xFF6D28D9), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Surplus Food In Transit',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4C1D95),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Vehicle en route to community kitchen. Both apps will update automatically upon delivery confirmation.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (mission.status == RescueStatus.delivered) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.task_alt_rounded,
                    color: AppColors.success, size: 22),
                SizedBox(width: 8),
                Text(
                  'MISSION DELIVERED & IMPACT RECORDED',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(mission.quantity * 2).round()} meals were successfully handed over to the community kitchen. Provide actual surplus quantity to improve our ML model accuracy.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.push(
                  '/sender/feedback/${mission.predictionId ?? widget.missionId}',
                  extra: mission,
                );
              },
              icon: const Icon(Icons.psychology_rounded, size: 18),
              label: const Text('Submit Prediction Feedback'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
