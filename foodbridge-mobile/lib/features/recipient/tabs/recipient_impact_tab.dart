import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/impact_service.dart';
import '../../../widgets/brand_identity_bar.dart';
import '../../../widgets/error_state_card.dart';
import '../../../widgets/impact_metric_card.dart';
import '../../../widgets/loading_state_view.dart';

class RecipientImpactTab extends ConsumerWidget {
  const RecipientImpactTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impactAsync = ref.watch(impactSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community Rescue Impact'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(impactSummaryProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Impact',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(impactSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FoodBridge Brand Pipeline Bar (Highlighting Impact)
              const BrandIdentityBar(activeStepIndex: 3),
              const SizedBox(height: 16),

              // Clean Impact Hero Card (Non-gradient)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
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
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'STEP 4: COLLECTIVE IMPACT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nourishing Lives, Diverting Food Waste',
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
                      'Real-time telemetry of surplus food diverted from landfills and delivered directly to community distribution centers.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Telemetry Section
              const Text(
                'LIVE RESCUE TELEMETRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              impactAsync.when(
                data: (impact) {
                  return Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          ImpactMetricCard(
                            label: 'Total Meals Rescued',
                            value: '${impact.totalMealsRescued}',
                            icon: Icons.restaurant_rounded,
                            accentColor: AppColors.primary,
                          ),
                          ImpactMetricCard(
                            label: 'Food Diverted',
                            value: impact.totalFoodKgRescued.toStringAsFixed(0),
                            unit: 'kg',
                            icon: Icons.scale_rounded,
                            accentColor: const Color(0xFF0284C7),
                          ),
                          ImpactMetricCard(
                            label: 'People Nourished',
                            value: '${impact.totalPeopleServed}',
                            icon: Icons.groups_rounded,
                            accentColor: AppColors.success,
                          ),
                          ImpactMetricCard(
                            label: 'Economic Value',
                            value:
                                '₹${impact.totalEstimatedValue.toStringAsFixed(0)}',
                            icon: Icons.currency_rupee_rounded,
                            accentColor: AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Environmental Benchmarks Card (Clearly Documented Assumptions)
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
                              children: const [
                                Icon(Icons.info_outline_rounded,
                                    size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Text(
                                  'CALCULATION METHODOLOGY & BENCHMARKS',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Impact figures are calculated using transparent FoodBridge operational assumptions: 0.4 kg average edible meal weight, ₹45 estimated meal value, and 1 meal per recipient served. Metrics reflect live completed delivery missions.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LoadingStateView(
                  message: 'Loading telemetry impact summary...',
                ),
                error: (e, _) => ErrorStateCard(
                  title: 'Unable to Load Impact Data',
                  message: e.toString(),
                  onRetry: () => ref.invalidate(impactSummaryProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
