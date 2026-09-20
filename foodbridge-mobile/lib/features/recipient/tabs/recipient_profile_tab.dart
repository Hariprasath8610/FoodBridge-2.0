import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/verified_badge.dart';
import '../../auth/server_config_dialog.dart';

class RecipientProfileTab extends ConsumerWidget {
  const RecipientProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Organization Profile'),
        actions: [
          IconButton(
            onPressed: () => ServerConfigDialog.show(context),
            icon: const Icon(Icons.dns_outlined),
            tooltip: 'Server Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF0284C7).withOpacity(0.1),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      size: 38,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.organizationName ?? 'Hope Community Kitchen',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'contact@hopekitchen.demo',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Verification Status Badge
                  const VerifiedBadge(
                    label: 'VERIFIED COMMUNITY RECIPIENT',
                    type: VerifiedType.recipient,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Organization Information Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORGANIZATION DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileRow(
                    icon: Icons.business,
                    label: 'Organization Type',
                    value: user?.organizationType.replaceAll('_', ' ').toUpperCase() ??
                        'COMMUNITY KITCHEN',
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    icon: Icons.badge_outlined,
                    label: 'Application Role',
                    value: 'Food Recipient (Phone 2)',
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    icon: Icons.place_outlined,
                    label: 'Service Area',
                    value: 'Gandhipuram, Coimbatore',
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    icon: Icons.schedule,
                    label: 'Receiving Availability',
                    value: '07:00 - 23:00 IST',
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    icon: Icons.phone_outlined,
                    label: 'Dispatch Contact',
                    value: '+91 98800 11111',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Operational Settings Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREFERENCES & SETTINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.tune,
                          size: 20, color: Color(0xFF0284C7)),
                    ),
                    title: const Text(
                      'Update Kitchen Demand',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Adjust daily meal target, dietary preference, hours',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/recipient/demand'),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.dns,
                          size: 20, color: AppColors.primary),
                    ),
                    title: const Text(
                      'Server Endpoint',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Configure backend FastAPI host & port',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ServerConfigDialog.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text(
                        'Are you sure you want to sign out from FoodBridge?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authServiceProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 18),
              label: const Text(
                'Sign Out from Kitchen Account',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
