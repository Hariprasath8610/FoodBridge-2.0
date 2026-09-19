import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/rescue_service.dart';

class FoodSafetyScreen extends ConsumerStatefulWidget {
  final String missionId;

  const FoodSafetyScreen({
    super.key,
    required this.missionId,
  });

  @override
  ConsumerState<FoodSafetyScreen> createState() => _FoodSafetyScreenState();
}

class _FoodSafetyScreenState extends ConsumerState<FoodSafetyScreen> {
  bool _tempAudit = true;
  bool _timeAudit = true;
  bool _packagingAudit = true;
  bool _allergenAudit = true;
  bool _isSubmitting = false;

  bool get _isAllChecked =>
      _tempAudit && _timeAudit && _packagingAudit && _allergenAudit;

  Future<void> _submitVerification() async {
    if (!_isAllChecked) return;
    setState(() => _isSubmitting = true);

    try {
      await ref.read(rescueServiceProvider).verifyFood(
            widget.missionId,
            passesHygiene: true,
            temperatureC: 68.5,
            notes: 'Certified food temperature, sanitary packaging, and allergen audit.',
          );
      ref.invalidate(activeRescuesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food safety certified! Ready for vehicle pickup.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
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
        title: const Text('Food Safety Certification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All donated surplus must pass strict hygiene and thermal holding standards before handoff.',
                      style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Checklist Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _tempAudit,
                    onChanged: (v) => setState(() => _tempAudit = v ?? false),
                    title: const Text(
                      'Temperature Standard Maintained',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Food held safely at >= 60°C (hot) or <= 4°C (chilled).',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    value: _timeAudit,
                    onChanged: (v) => setState(() => _timeAudit = v ?? false),
                    title: const Text(
                      'Safe Holding Window',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Prepared within the last 4 hours under sanitary conditions.',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    value: _packagingAudit,
                    onChanged: (v) => setState(() => _packagingAudit = v ?? false),
                    title: const Text(
                      'Food-Grade Airtight Packaging',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Sealed in sanitized, spill-proof containers.',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    value: _allergenAudit,
                    onChanged: (v) => setState(() => _allergenAudit = v ?? false),
                    title: const Text(
                      'Ingredient & Dietary Transparency',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Matches declared dietary category (Vegetarian / Non-Veg).',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: (_isAllChecked && !_isSubmitting) ? _submitVerification : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified),
              label: Text(_isSubmitting ? 'Certifying...' : 'Certify Food Safety & Sign Off'),
            ),
          ],
        ),
      ),
    );
  }
}
