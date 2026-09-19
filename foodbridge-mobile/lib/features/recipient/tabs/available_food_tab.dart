import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/food_listing_model.dart';
import '../../../services/listing_service.dart';
import '../../../services/rescue_service.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_state_card.dart';
import '../../../widgets/loading_state_view.dart';
import '../../../widgets/verified_badge.dart';

class AvailableFoodTab extends ConsumerStatefulWidget {
  final Function(int targetTab)? onNavigateTab;

  const AvailableFoodTab({
    super.key,
    this.onNavigateTab,
  });

  @override
  ConsumerState<AvailableFoodTab> createState() => _AvailableFoodTabState();
}

class _AvailableFoodTabState extends ConsumerState<AvailableFoodTab> {
  String _selectedFilter = 'ALL';
  // Recipient demo coordinates (Hope Community Kitchen, Shivajinagar, Bangalore)
  static const double recipientLat = 12.9785;
  static const double recipientLng = 77.6010;

  void _showClaimDialog(BuildContext context, FoodListingModel listing) {
    int requestedPortions = listing.quantityServings;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.volunteer_activism_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Request Food Rescue',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    listing.providerName,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.scale_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${listing.weightKg.toStringAsFixed(1)} kg available (~ ${listing.quantityServings} portions)',
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
                  const SizedBox(height: 18),
                  const Text(
                    'PORTIONS TO CLAIM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: requestedPortions > 10
                            ? () {
                                setModalState(() {
                                  requestedPortions =
                                      (requestedPortions - 10).clamp(10, listing.quantityServings);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        iconSize: 28,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '$requestedPortions Meals',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: requestedPortions < listing.quantityServings
                            ? () {
                                setModalState(() {
                                  requestedPortions =
                                      (requestedPortions + 10).clamp(10, listing.quantityServings);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        iconSize: 28,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Most Important Action Obvious: Confirm Request
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              await ref.read(rescueServiceProvider).requestFood(
                                    providerId: listing.providerId,
                                    foodSourceId: listing.id,
                                    quantity: requestedPortions.toDouble(),
                                  );

                              ref.invalidate(activeRescuesProvider);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Food request for $requestedPortions meals submitted successfully!'),
                                    backgroundColor: AppColors.primary,
                                    action: SnackBarAction(
                                      label: 'View Requests',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        if (widget.onNavigateTab != null) {
                                          widget.onNavigateTab!(2);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Request failed: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(isSubmitting
                        ? 'Submitting Request...'
                        : 'Confirm & Request $requestedPortions Meals'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(availableListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Available Surplus Food'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(availableListingsProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Listings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Filter:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All Food'),
                  selected: _selectedFilter == 'ALL',
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = 'ALL');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Veg'),
                  selected: _selectedFilter == 'VEG',
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = 'VEG');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Non-Veg'),
                  selected: _selectedFilter == 'NON_VEG',
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = 'NON_VEG');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Listings List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(availableListingsProvider);
              },
              child: listingsAsync.when(
                data: (listings) {
                  final filtered = listings.where((l) {
                    if (_selectedFilter == 'ALL') return true;
                    return l.foodType.toUpperCase() == _selectedFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.fastfood_outlined,
                      title: 'No Surplus Food Available Right Now',
                      description:
                          'When verified food providers in Bangalore log surplus meals, they will appear here in real time for immediate rescue.',
                      actionLabel: 'Refresh Listings',
                      onAction: () => ref.invalidate(availableListingsProvider),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildFoodCard(item);
                    },
                  );
                },
                loading: () => const LoadingStateView(
                  message: 'Scanning verified surplus listings...',
                  subMessage: 'Calculating distance and dietary compatibility',
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ErrorStateCard(
                      title: 'Unable to Load Listings',
                      message: e.toString(),
                      onRetry: () => ref.invalidate(availableListingsProvider),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(FoodListingModel item) {
    final distanceKm =
        item.distanceTo(recipientLat, recipientLng);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title and Dietary Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
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
                        Flexible(
                          child: Text(
                            item.providerName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.foodType.toUpperCase() == 'VEG'
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.foodType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: item.foodType.toUpperCase() == 'VEG'
                        ? const Color(0xFF047857)
                        : const Color(0xFFB45309),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Details Row: Distance, Quantity, Available Until
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.near_me_outlined,
                  '${distanceKm.toStringAsFixed(1)} km',
                  'DISTANCE',
                ),
                Container(width: 1, height: 24, color: AppColors.border),
                _buildInfoItem(
                  Icons.restaurant_menu_rounded,
                  '${item.weightKg.toStringAsFixed(0)} kg',
                  '~ ${item.quantityServings} MEALS',
                ),
                Container(width: 1, height: 24, color: AppColors.border),
                _buildInfoItem(
                  Icons.schedule_rounded,
                  item.expiryTime,
                  'EXPIRY WINDOW',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Most Important Action Obvious: REQUEST FOOD Button (min 48px height)
          ElevatedButton.icon(
            onPressed: () => _showClaimDialog(context, item),
            icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
            label: const Text('REQUEST FOOD RESCUE'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
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
