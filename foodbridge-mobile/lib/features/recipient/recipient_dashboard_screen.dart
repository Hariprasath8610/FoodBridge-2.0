import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rescue_model.dart';
import '../../services/auth_service.dart';
import '../../services/impact_service.dart';
import '../../services/rescue_service.dart';
import '../../widgets/impact_metric_card.dart';
import '../../widgets/mission_status_badge.dart';
import '../auth/server_config_dialog.dart';

class RecipientDashboardScreen extends ConsumerWidget {
  const RecipientDashboardScreen({super.key});

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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.organizationName ?? 'Community Kitchen',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'VERIFIED RECIPIENT (PHONE 2)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
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
              // Recipient Daily Demand Hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.kitchen, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'KITCHEN DEMAND READY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ready to Receive Surplus Meals',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your kitchen is connected to the FoodBridge matching engine. Keep your daily capacity updated.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/recipient/demand'),
                      icon: const Icon(Icons.tune,
                          size: 18, color: AppColors.primaryDark),
                      label: const Text(
                        'Adjust Meal Demand & Capacity',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Network Impact Summary
              const Text(
                'COMMUNITY RESCUE IMPACT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              impactAsync.when(
                data: (impact) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    ImpactMetricCard(
                      label: 'Meals Distributed',
                      value: '${impact.totalMealsRescued}',
                      icon: Icons.dinner_dining_rounded,
                      accentColor: AppColors.primary,
                    ),
                    ImpactMetricCard(
                      label: 'Food Received',
                      value: '${impact.totalFoodKgRescued.toStringAsFixed(0)}',
                      unit: 'kg',
                      icon: Icons.inventory_2_outlined,
                      accentColor: AppColors.secondary,
                    ),
                    ImpactMetricCard(
                      label: 'People Nourished',
                      value: '${impact.totalPeopleServed}',
                      icon: Icons.people_alt_rounded,
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
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => ImpactMetricCard(
                  label: 'Community Kitchen',
                  value: 'Online',
                  icon: Icons.check,
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              // Incoming Rescue Transfers Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INCOMING RESCUES & MISSIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(activeRescuesProvider),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Missions List
              rescuesAsync.when(
                data: (missions) {
                  if (missions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.markunread_mailbox_outlined,
                                size: 36, color: AppColors.textLight),
                            SizedBox(height: 8),
                            Text(
                              'No incoming rescues right now.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'When a provider dispatches surplus from Phone 1, it will appear here automatically.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: missions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final mission = missions[index];
                      return _buildRecipientMissionCard(context, mission);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Error loading missions: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientMissionCard(
      BuildContext context, RescueMission mission) {
    final isInTransit = mission.status == RescueStatus.inTransit ||
        mission.status == RescueStatus.pickedUp;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/recipient/mission/${mission.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isInTransit ? AppColors.secondary : AppColors.border,
              width: isInTransit ? 2 : 1,
            ),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.restaurant,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    mission.providerName ?? 'GreenLeaf Hotel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${mission.quantity.toStringAsFixed(0)} kg (~${(mission.quantity * 2).round()} meals)',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (isInTransit) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.local_shipping,
                          size: 14, color: AppColors.primaryDark),
                      SizedBox(width: 6),
                      Text(
                        'En Route • Tap to Confirm Delivery',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
