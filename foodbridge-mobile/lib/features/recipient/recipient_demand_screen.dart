import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/matching_service.dart';

class RecipientDemandScreen extends ConsumerStatefulWidget {
  const RecipientDemandScreen({super.key});

  @override
  ConsumerState<RecipientDemandScreen> createState() =>
      _RecipientDemandScreenState();
}

class _RecipientDemandScreenState extends ConsumerState<RecipientDemandScreen> {
  final _peopleNeedingFoodController = TextEditingController(text: '250');
  final _demandController = TextEditingController(text: '120');
  String _foodPreference = 'all'; // 'all', 'vegetarian', 'non_veg'
  TimeOfDay _availabilityStart = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _availabilityEnd = const TimeOfDay(hour: 23, minute: 0);
  bool _isSaving = false;

  @override
  void dispose() {
    _peopleNeedingFoodController.dispose();
    _demandController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart ? _availabilityStart : _availabilityEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _availabilityStart = picked;
        } else {
          _availabilityEnd = picked;
        }
      });
    }
  }

  Future<void> _updateDemand() async {
    final currentDemand = int.tryParse(_demandController.text.trim());
    final peopleNeedingFood =
        int.tryParse(_peopleNeedingFoodController.text.trim());

    if (currentDemand == null || currentDemand < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid current meal demand')),
      );
      return;
    }

    if (peopleNeedingFood == null || peopleNeedingFood <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter people needing food daily')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(matchingServiceProvider).updateRecipientDemand(
            currentDemand: currentDemand,
            peopleServed: peopleNeedingFood,
            foodPreferences: _foodPreference,
            availabilityStart: _formatTime(_availabilityStart),
            availabilityEnd: _formatTime(_availabilityEnd),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Kitchen demand updated: $currentDemand meals for $peopleNeedingFood people.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update demand: $e'),
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
        title: const Text('Update Kitchen Demand'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational Notice Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.hub_outlined,
                      color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The AI matching engine uses your meal demand, people served, dietary preferences, and operational hours to prioritize allocations when nearby surplus is predicted.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Form Section
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
                    'DAILY FOOD CAPACITY & TARGETS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. People Needing Food
                  TextField(
                    controller: _peopleNeedingFoodController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'People Needing Food Daily',
                      hintText: 'e.g. 250',
                      prefixIcon: Icon(Icons.people_outline, size: 20),
                      suffixText: 'people',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Current Demand (Meals)
                  TextField(
                    controller: _demandController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Meal Demand Today',
                      hintText: 'e.g. 120',
                      prefixIcon: Icon(Icons.soup_kitchen_outlined, size: 20),
                      suffixText: 'meals',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick presets
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('60 Meals'),
                        onPressed: () =>
                            setState(() => _demandController.text = '60'),
                      ),
                      ActionChip(
                        label: const Text('120 Meals (Standard)'),
                        onPressed: () =>
                            setState(() => _demandController.text = '120'),
                      ),
                      ActionChip(
                        label: const Text('200 Meals (High)'),
                        onPressed: () =>
                            setState(() => _demandController.text = '200'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Food Preference
                  const Text(
                    'DIETARY PREFERENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('All Diets')),
                          selected: _foodPreference == 'all',
                          onSelected: (val) {
                            if (val) setState(() => _foodPreference = 'all');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Vegetarian')),
                          selected: _foodPreference == 'vegetarian',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _foodPreference = 'vegetarian');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Non-Veg')),
                          selected: _foodPreference == 'non_veg',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _foodPreference = 'non_veg');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Availability Window
                  const Text(
                    'OPERATIONAL RECEIVING WINDOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(true),
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(
                              'From: ${_formatTime(_availabilityStart)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(false),
                          icon: const Icon(Icons.access_time_filled, size: 16),
                          label: Text('To: ${_formatTime(_availabilityEnd)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Most Important Action Obvious: Update Demand CTA
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _updateDemand,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                _isSaving ? 'Updating Demand...' : 'Broadcast Kitchen Demand',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
