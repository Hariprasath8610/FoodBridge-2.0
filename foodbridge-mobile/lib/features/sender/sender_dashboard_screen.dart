import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rescue_model.dart';
import '../../services/auth_service.dart';
import '../../services/impact_service.dart';
import '../../services/rescue_service.dart';
import '../../widgets/brand_identity_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_card.dart';
import '../../widgets/impact_metric_card.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/mission_status_badge.dart';
import '../../widgets/verified_badge.dart';
import '../auth/server_config_dialog.dart';

class SenderDashboardScreen extends ConsumerWidget {
  const SenderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final user = authState.user;
    final impactAsync = ref.watch(impactSummaryProvider);
    final rescuesAsync = ref.watch(activeRescuesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.organizationName ?? 'GreenLeaf Hotel',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const VerifiedBadge(
                    type: VerifiedType.provider,
                    isCompact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ServerConfigDialog.show(context),
            icon: const Icon(Icons.dns_outlined, size: 20),
            tooltip: 'Server Settings',
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authServiceProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(impactSummaryProvider);
          ref.invalidate(activeRescuesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FoodBridge Brand Pipeline Bar
              const BrandIdentityBar(activeStepIndex: 0),
              const SizedBox(height: 16),

              // AI Surplus Prediction Call-to-Action Hero (Clean, Non-gradient)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'STEP 1: SURPLUS PREDICTION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Forecast Surplus Before Food Spoils',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use machine learning to estimate surplus quantity from guests, menu category, and weather risk. Connect directly with nearby verified recipients.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Most Important Action Obvious
                    ElevatedButton.icon(
                      onPressed: () => context.push('/sender/predict'),
                      icon: const Icon(Icons.insights, size: 18),
                      label: const Text('Predict Surplus Food'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Operational Impact Metrics
              const Text(
                'COLLECTIVE IMPACT TELEMETRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              impactAsync.when(
                data: (impact) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    ImpactMetricCard(
                      label: 'Meals Rescued',
                      value: '${impact.totalMealsRescued}',
                      icon: Icons.rice_bowl_rounded,
                      accentColor: AppColors.primary,
                    ),
                    ImpactMetricCard(
                      label: 'Food Saved',
                      value: impact.totalFoodKgRescued.toStringAsFixed(0),
                      unit: 'kg',
                      icon: Icons.scale_rounded,
                      accentColor: const Color(0xFF0284C7),
                    ),
                    ImpactMetricCard(
                      label: 'People Fed',
                      value: '${impact.totalPeopleServed}',
                      icon: Icons.groups_rounded,
                      accentColor: AppColors.success,
                    ),
                    ImpactMetricCard(
                      label: 'Completed Rescues',
                      value: '${impact.totalRescues}',
                      icon: Icons.task_alt_rounded,
                      accentColor: AppColors.warning,
                    ),
                  ],
                ),
                loading: () => const LoadingStateView(message: 'Loading telemetry metrics...'),
                error: (e, _) => ErrorStateCard(
                  message: 'Could not load impact telemetry: $e',
                  onRetry: () => ref.invalidate(impactSummaryProvider),
                ),
              ),
              const SizedBox(height: 28),

              // Active Rescue Missions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ACTIVE RESCUE MISSIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(activeRescuesProvider),
                    child: const Text('Refresh Feed'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Missions List
              rescuesAsync.when(
                data: (missions) {
                  if (missions.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Active Missions',
                      description: 'When surplus food is predicted and requested by verified recipients, your dispatch operations will be tracked here in real-time.',
                      actionLabel: 'Predict Surplus Now',
                      onAction: () => context.push('/sender/predict'),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: missions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final mission = missions[index];
                      return _buildMissionCard(context, mission);
                    },
                  );
                },
                loading: () => const LoadingStateView(message: 'Loading active missions...'),
                error: (e, _) => ErrorStateCard(
                  message: 'Could not load active rescue missions: $e',
                  onRetry: () => ref.invalidate(activeRescuesProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, RescueMission mission) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/sender/mission/${mission.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mission.rescueCode,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  MissionStatusBadge(status: mission.status, isCompact: true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.volunteer_activism_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            mission.recipientName ?? 'CareBridge Community',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
                  ),
                  Text(
                    '${mission.quantity.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Manage Mission →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
