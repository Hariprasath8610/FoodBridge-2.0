import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/rescue_model.dart';
import '../../../services/impact_service.dart';
import '../../../services/rescue_service.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/error_state_card.dart';
import '../../../widgets/loading_state_view.dart';
import '../../../widgets/mission_status_badge.dart';
import '../../../widgets/qr_scanner_sheet.dart';
import '../../../widgets/verified_badge.dart';

class RecipientRequestsTab extends ConsumerStatefulWidget {
  const RecipientRequestsTab({super.key});

  @override
  ConsumerState<RecipientRequestsTab> createState() =>
      _RecipientRequestsTabState();
}

class _RecipientRequestsTabState extends ConsumerState<RecipientRequestsTab> {
  String _selectedStatusFilter = 'ALL';

  Future<void> _scanVerificationCode(RescueMission mission) async {
    final scanned = await QrScannerSheet.show(
      context,
      title: 'Scan Rescue QR',
      prompt: 'Point camera at the Provider QR or enter fallback OTP',
    );

    if (scanned != null && scanned.isNotEmpty && mounted) {
      try {
        final clean = scanned.trim();
        if (clean.length == 6 && int.tryParse(clean) != null) {
          // Numeric OTP fallback
          if (mission.status == RescueStatus.foodVerified ||
              mission.status == RescueStatus.pickupReady) {
            await ref
                .read(rescueServiceProvider)
                .verifyPickup(mission.id, otp: clean);
          } else {
            await ref
                .read(rescueServiceProvider)
                .verifyDelivery(mission.id, otp: clean);
          }
        } else {
          // Safe QR rescue code verification
          await ref.read(rescueServiceProvider).verifyQr(
                qrData: clean,
                rescueId: int.tryParse(mission.id),
              );
        }

        ref.invalidate(activeRescuesProvider);
        ref.invalidate(impactSummaryProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rescue verification confirmed! Status updated.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rescuesAsync = ref.watch(activeRescuesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Rescue Requests'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(activeRescuesProvider);
              ref.invalidate(impactSummaryProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Requests',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Scrollable Header
          Container(
            color: Colors.white,
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildFilterChip('ALL', 'All'),
                _buildFilterChip('PENDING', 'Pending'),
                _buildFilterChip('APPROVED', 'Approved'),
                _buildFilterChip('PICKUP_READY', 'Pickup Ready'),
                _buildFilterChip('IN_TRANSIT', 'In Transit'),
                _buildFilterChip('DELIVERED', 'Delivered'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Requests List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activeRescuesProvider);
              },
              child: rescuesAsync.when(
                data: (missions) {
                  final filtered = missions.where((m) {
                    if (_selectedStatusFilter == 'ALL') return true;
                    if (_selectedStatusFilter == 'PENDING') {
                      return m.status == RescueStatus.recipientRequested ||
                          m.status == RescueStatus.created;
                    }
                    if (_selectedStatusFilter == 'APPROVED') {
                      return m.status == RescueStatus.providerApproved;
                    }
                    if (_selectedStatusFilter == 'PICKUP_READY') {
                      return m.status == RescueStatus.foodVerified ||
                          m.status == RescueStatus.pickupReady;
                    }
                    if (_selectedStatusFilter == 'IN_TRANSIT') {
                      return m.status == RescueStatus.inTransit ||
                          m.status == RescueStatus.pickedUp;
                    }
                    if (_selectedStatusFilter == 'DELIVERED') {
                      return m.status == RescueStatus.delivered;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.history_rounded,
                      title: 'No Rescue Requests in this Status',
                      description:
                          'When your kitchen requests surplus food, the missions and real-time delivery lifecycle will appear here.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final mission = filtered[index];
                      return _buildRequestCard(mission);
                    },
                  );
                },
                loading: () => const LoadingStateView(
                  message: 'Loading your rescue requests...',
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ErrorStateCard(
                      title: 'Unable to Load Requests',
                      message: e.toString(),
                      onRetry: () => ref.invalidate(activeRescuesProvider),
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

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedStatusFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedStatusFilter = filterKey);
        },
      ),
    );
  }

  Widget _buildRequestCard(RescueMission mission) {
    final isInTransit = mission.status == RescueStatus.inTransit ||
        mission.status == RescueStatus.pickedUp;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInTransit ? const Color(0xFF6D28D9) : AppColors.border,
          width: isInTransit ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Code & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mission.rescueCode,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              MissionStatusBadge(status: mission.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 12),

          // Provider info
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '~ ${(mission.quantity * 2).round()} Meals for community distribution',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Obvious Action Button Depending on Status
          if (isInTransit) ...[
            ElevatedButton.icon(
              onPressed: () =>
                  context.push('/recipient/delivery', extra: mission),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('CONFIRM DELIVERY (SCAN / OTP)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
              ),
            ),
          ] else if (mission.status == RescueStatus.foodVerified ||
              mission.status == RescueStatus.pickupReady) ...[
            OutlinedButton.icon(
              onPressed: () => _scanVerificationCode(mission),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Verify Pickup Pass'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ] else ...[
            OutlinedButton(
              onPressed: () =>
                  context.push('/recipient/mission/${mission.id}'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('View Mission Details'),
            ),
          ],
        ],
      ),
    );
  }
}
