import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/matching_model.dart';
import '../../models/prediction_model.dart';
import '../../services/auth_service.dart';
import '../../services/matching_service.dart';
import '../../services/rescue_service.dart';
import '../../widgets/brand_identity_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_card.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/verified_badge.dart';

class MatchingResultsScreen extends ConsumerStatefulWidget {
  final String predictionId;
  final PredictionResponse? prediction;

  const MatchingResultsScreen({
    super.key,
    required this.predictionId,
    this.prediction,
  });

  @override
  ConsumerState<MatchingResultsScreen> createState() =>
      _MatchingResultsScreenState();
}

class _MatchingResultsScreenState extends ConsumerState<MatchingResultsScreen> {
  late Future<List<MatchResult>> _matchesFuture;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    _matchesFuture =
        ref.read(matchingServiceProvider).getMatches(widget.predictionId);
  }

  Future<void> _dispatchMission(MatchResult match) async {
    final auth = ref.read(authServiceProvider);
    if (auth.isSender) {
      ref.invalidate(activeRescuesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Match locked! ${match.recipient.organizationName} (${match.scorePercentage}% match) notified. They can now confirm rescue.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
      context.go('/sender/dashboard');
      return;
    }

    setState(() => _isRequesting = true);
    try {
      final quantity = match.compatibleQuantity > 0
          ? match.compatibleQuantity
          : (widget.prediction?.predictedSurplus ?? 70.0);

      final mission = await ref.read(rescueServiceProvider).requestFood(
            providerId: 1,
            predictionId: widget.predictionId,
            quantity: quantity,
          );

      if (mounted) {
        ref.invalidate(activeRescuesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rescue Mission ${mission.rescueCode} requested!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pushReplacement('/recipient/mission/${mission.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequesting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request rescue: $e'),
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
        title: const Text('Intelligent Recipient Matches'),
      ),
      body: FutureBuilder<List<MatchResult>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isRequesting) {
            return LoadingStateView(
              message: _isRequesting
                  ? 'Dispatching Rescue Mission...'
                  : 'Evaluating Verified Recipients...',
              subMessage: 'Optimizing for travel distance, capacity, and urgency',
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ErrorStateCard(
                  title: 'Unable to Load Matches',
                  message: snapshot.error.toString(),
                  onRetry: () {
                    setState(() {
                      _loadMatches();
                    });
                  },
                ),
              ),
            );
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'No Matching Recipients Found',
              description:
                  'All nearby recipient community centers might currently be at maximum storage capacity or outside operating hours.',
              actionLabel: 'Return to Dashboard',
              onAction: () => context.go('/sender/dashboard'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20.0),
            itemCount: matches.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    BrandIdentityBar(activeStepIndex: 1),
                    SizedBox(height: 16),
                    Text(
                      'RANKED COMMUNITY RECIPIENTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                );
              }

              final match = matches[index - 1];
              return _buildMatchCard(match, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(MatchResult match, int rank) {
    final recipient = match.recipient;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1 ? AppColors.primary : AppColors.border,
          width: rank == 1 ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Match Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rank == 1)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TOP OPTIMAL MATCH #1',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      recipient.organizationName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const VerifiedBadge(
                          type: VerifiedType.recipient,
                          isCompact: true,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Serves ${recipient.peopleServed} people/day',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Match Score Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      '${(match.matchScore * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'MATCH',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Match Metrics Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol(
                  Icons.near_me_outlined,
                  '${match.distanceKm.toStringAsFixed(1)} km',
                  'DISTANCE',
                ),
                Container(width: 1, height: 24, color: AppColors.border),
                _buildMetricCol(
                  Icons.restaurant_outlined,
                  '${match.currentDemand} meals',
                  'DEMAND',
                ),
                Container(width: 1, height: 24, color: AppColors.border),
                _buildMetricCol(
                  Icons.schedule_rounded,
                  match.urgency.toUpperCase(),
                  'URGENCY',
                  color: match.urgency.toLowerCase() == 'high'
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Reason line
          if (match.reason.isNotEmpty) ...[
            Text(
              'Reason: ${match.reason}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Most Important Action Obvious: Dispatch Rescue
          ElevatedButton.icon(
            onPressed: _isRequesting ? null : () => _dispatchMission(match),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(
              'Dispatch Food to ${recipient.organizationName}',
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor:
                  rank == 1 ? AppColors.primary : AppColors.obsidian,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(IconData icon, String value, String label,
      {Color? color}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
