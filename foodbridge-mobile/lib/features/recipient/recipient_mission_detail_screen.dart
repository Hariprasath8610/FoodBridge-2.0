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

class RecipientMissionDetailScreen extends ConsumerStatefulWidget {
  final String missionId;

  const RecipientMissionDetailScreen({
    super.key,
    required this.missionId,
  });

  @override
  ConsumerState<RecipientMissionDetailScreen> createState() =>
      _RecipientMissionDetailScreenState();
}

class _RecipientMissionDetailScreenState
    extends ConsumerState<RecipientMissionDetailScreen> {
  late Future<RescueMission> _missionFuture;

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  void _loadMission() {
    _missionFuture =
        ref.read(rescueServiceProvider).getRescue(widget.missionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incoming Rescue Mission'),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingStateView(
              message: 'Loading rescue mission details...',
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

                // Header Card
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
                                'RESCUE TRACKING CODE',
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
                                  'FOOD PROVIDER FACILITY',
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
                                        mission.providerName ??
                                            'GreenLeaf Hotel',
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
                                      type: VerifiedType.provider,
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
                                  color: Color(0xFF0284C7),
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

                // Stepper Progression
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
                        'RESCUE PROGRESSION',
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

                // Contextual Recipient Actions
                _buildRecipientActions(context, mission),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipientActions(BuildContext context, RescueMission mission) {
    if (mission.status == RescueStatus.inTransit ||
        mission.status == RescueStatus.pickedUp) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6D28D9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.local_shipping_rounded,
                    color: Color(0xFF6D28D9), size: 20),
                SizedBox(width: 8),
                Text(
                  'FOOD SHIPMENT IN TRANSIT',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4C1D95),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'The vehicle has arrived or is approaching your kitchen loading dock. Confirm handover using the driver QR scan or fallback OTP.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final completed = await context.push<bool>(
                  '/recipient/mission/${mission.id}/deliver',
                  extra: mission,
                );
                if (completed == true) {
                  _loadMission();
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Confirm Delivery Handover (QR / OTP)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      );
    }

    if (mission.status == RescueStatus.delivered) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success, width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.task_alt_rounded,
                color: AppColors.success, size: 36),
            const SizedBox(height: 10),
            const Text(
              'DELIVERY COMPLETE',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(mission.quantity * 2).round()} meals received safely and recorded in the FoodBridge impact registry.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Pending stages
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: const [
          Icon(Icons.hourglass_empty_rounded,
              color: AppColors.textSecondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Awaiting vehicle loading at the provider facility. Delivery confirmation will activate once in transit.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
