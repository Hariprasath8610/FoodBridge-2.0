import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rescue_model.dart';
import '../../services/listing_service.dart';
import '../../services/rescue_service.dart';
import 'tabs/available_food_tab.dart';
import 'tabs/recipient_home_tab.dart';
import 'tabs/recipient_impact_tab.dart';
import 'tabs/recipient_profile_tab.dart';
import 'tabs/recipient_requests_tab.dart';

class RecipientShellScreen extends ConsumerStatefulWidget {
  const RecipientShellScreen({super.key});

  @override
  ConsumerState<RecipientShellScreen> createState() =>
      _RecipientShellScreenState();
}

class _RecipientShellScreenState extends ConsumerState<RecipientShellScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeRescuesAsync = ref.watch(activeRescuesProvider);
    final availableListingsAsync = ref.watch(availableListingsProvider);

    // Calculate badges
    final activeCount = activeRescuesAsync.when(
      data: (missions) => missions
          .where((m) =>
              m.status != RescueStatus.delivered &&
              m.status != RescueStatus.cancelled)
          .length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final availableCount = availableListingsAsync.when(
      data: (listings) => listings.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final List<Widget> tabs = [
      RecipientHomeTab(onNavigateTab: _onTabTapped),
      AvailableFoodTab(onNavigateTab: _onTabTapped),
      const RecipientRequestsTab(),
      const RecipientImpactTab(),
      const RecipientProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.secondary.withOpacity(0.18),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primaryDark),
            label: 'Home',
          ),
          NavigationDestination(
            icon: availableCount > 0
                ? Badge(
                    label: Text('$availableCount'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.fastfood_outlined),
                  )
                : const Icon(Icons.fastfood_outlined),
            selectedIcon: const Icon(Icons.fastfood, color: AppColors.primaryDark),
            label: 'Available',
          ),
          NavigationDestination(
            icon: activeCount > 0
                ? Badge(
                    label: Text('$activeCount'),
                    backgroundColor: AppColors.secondary,
                    child: const Icon(Icons.receipt_long_outlined),
                  )
                : const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long, color: AppColors.primaryDark),
            label: 'Requests',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppColors.primaryDark),
            label: 'Impact',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle, color: AppColors.primaryDark),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
