import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/rescue_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/impact_service.dart';
import '../../../services/rescue_service.dart';
import '../../../widgets/brand_identity_bar.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_state_card.dart';
import '../../../widgets/impact_metric_card.dart';
import '../../../widgets/loading_state_view.dart';
import '../../../widgets/mission_status_badge.dart';
import '../../../widgets/verified_badge.dart';

class RecipientHomeTab extends ConsumerWidget {
  final Function(int targetTab)? onNavigateTab;

  const RecipientHomeTab({
    super.key,
    this.onNavigateTab,
  });

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
                color: const Color(0xFF0284C7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: Color(0xFF0284C7),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.organizationName ?? 'Hope Community Kitchen',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const VerifiedBadge(
                    type: VerifiedType.recipient,
                    isCompact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(activeRescuesProvider);
              ref.invalidate(impactSummaryProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Feed',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeRescuesProvider);
          ref.invalidate(impactSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FoodBridge Brand Pipeline Bar
              const BrandIdentityBar(activeStepIndex: 1),
              const SizedBox(height: 16),

              // Clean Human-Centered Recipient Hero Card (Non-gradient)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0284C7).withOpacity(0.3),
                    width: 1.5,
                  ),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COMMUNITY NOURISHMENT DESK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0369A1),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.radar_rounded,
                          color: Color(0xFF0284C7),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ready to Receive Surplus Meals',
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
                      'Matched automatically with hotels, weddings, and institutional cafeterias across Bangalore to bridge food waste to community meals.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Two obvious accessible buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (onNavigateTab != null) {
                                onNavigateTab!(1); // Go to Available Food tab
                              }
                            },
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Browse Food'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/recipient/demand'),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Update Demand'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Operational Telemetry Overview
              const Text(
                'COMMUNITY KITCHEN IMPACT',
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
                      label: 'Meals Received',
                      value: '${impact.totalMealsRescued}',
                      icon: Icons.rice_bowl_rounded,
                      accentColor: const Color(0xFF0284C7),
                    ),
                    ImpactMetricCard(
                      label: 'Food Rescued',
                      value: impact.totalFoodKgRescued.toStringAsFixed(0),
                      unit: 'kg',
                      icon: Icons.scale_rounded,
                      accentColor: AppColors.primary,
                    ),
                    ImpactMetricCard(
                      label: 'People Fed',
                      value: '${impact.totalPeopleServed}',
                      icon: Icons.groups_rounded,
                      accentColor: AppColors.success,
                    ),
                    ImpactMetricCard(
                      label: 'Completed Missions',
                      value: '${impact.totalRescues}',
                      icon: Icons.task_alt_rounded,
                      accentColor: AppColors.warning,
                    ),
                  ],
                ),
                loading: () =>
                    const LoadingStateView(message: 'Loading telemetry metrics...'),
                error: (e, _) => ErrorStateCard(
                  message: 'Could not load kitchen impact telemetry: $e',
                  onRetry: () => ref.invalidate(impactSummaryProvider),
                ),
              ),
              const SizedBox(height: 28),

              // Active Rescues Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INCOMING RESCUE MISSIONS',
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
                      icon: Icons.volunteer_activism_outlined,
                      title: 'No Incoming Deliveries',
                      description:
                          'Surplus food claimed or matched from verified providers will show up here with real-time transit status.',
                      actionLabel: 'Browse Available Food',
                      onAction: () => onNavigateTab?.call(1),
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
                loading: () =>
                    const LoadingStateView(message: 'Loading active missions...'),
                error: (e, _) => ErrorStateCard(
                  message: 'Could not load active rescues: $e',
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
        onTap: () {
          if (mission.status == RescueStatus.inTransit ||
              mission.status == RescueStatus.pickedUp) {
            context.push('/recipient/delivery', extra: mission);
          } else {
            context.push('/recipient/mission/${mission.id}');
          }
        },
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
                  const Icon(Icons.restaurant_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            mission.providerName ?? 'GreenLeaf Hotel',
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
                          type: VerifiedType.provider,
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
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    mission.status == RescueStatus.inTransit
                        ? 'Confirm Delivery (Scan/OTP) →'
                        : 'View Details →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: mission.status == RescueStatus.inTransit
                          ? const Color(0xFF6D28D9)
                          : const Color(0xFF0284C7),
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
