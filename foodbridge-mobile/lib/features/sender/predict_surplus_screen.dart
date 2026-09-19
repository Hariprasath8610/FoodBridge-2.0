import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/prediction_model.dart';
import '../../services/prediction_service.dart';
import '../../widgets/brand_identity_bar.dart';
import '../../widgets/error_state_card.dart';

class PredictSurplusScreen extends ConsumerStatefulWidget {
  const PredictSurplusScreen({super.key});

  @override
  ConsumerState<PredictSurplusScreen> createState() => _PredictSurplusScreenState();
}

class _PredictSurplusScreenState extends ConsumerState<PredictSurplusScreen> {
  final _expectedPeopleController = TextEditingController(text: '500');
  final _plannedMealsController = TextEditingController(text: '500');
  final _currentAttendanceController = TextEditingController(text: '430');
  final _historicalRateController = TextEditingController(text: '0.92');

  String _eventType = 'wedding';
  String _menuCategory = 'vegetarian';
  String _weather = 'heavy_rain';
  String _dayOfWeek = 'saturday';

  bool _isLoading = false;
  PredictionResponse? _predictionResult;
  String? _errorMessage;

  @override
  void dispose() {
    _expectedPeopleController.dispose();
    _plannedMealsController.dispose();
    _currentAttendanceController.dispose();
    _historicalRateController.dispose();
    super.dispose();
  }

  void _fillWeddingScenario() {
    setState(() {
      _expectedPeopleController.text = '500';
      _plannedMealsController.text = '500';
      _currentAttendanceController.text = '430';
      _historicalRateController.text = '0.92';
      _eventType = 'wedding';
      _menuCategory = 'vegetarian';
      _weather = 'heavy_rain';
      _dayOfWeek = 'saturday';
      _predictionResult = null;
      _errorMessage = null;
    });
  }

  Future<void> _runSurplusPrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final expectedPeople = int.tryParse(_expectedPeopleController.text) ?? 500;
      final plannedQty = double.tryParse(_plannedMealsController.text) ?? 500.0;
      final currentAtt = int.tryParse(_currentAttendanceController.text) ?? 430;
      final histRate = double.tryParse(_historicalRateController.text) ?? 0.92;

      final request = PredictionRequest(
        expectedPeople: expectedPeople,
        plannedQuantity: plannedQty,
        historicalAttendanceRate: histRate,
        currentAttendance: currentAtt,
        eventType: _eventType,
        menuCategory: _menuCategory,
        weatherCondition: _weather,
        dayOfWeek: _dayOfWeek,
        historicalSurplusRate: 0.08,
      );

      final service = ref.read(predictionServiceProvider);
      final result = await service.createPrediction(request);

      setState(() {
        _predictionResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Surplus Prediction Engine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FoodBridge Brand Pipeline Bar (Highlighting Predict)
            const BrandIdentityBar(activeStepIndex: 0),
            const SizedBox(height: 16),

            // Quick preset demo button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Scenario: Grand Wedding (500 meals, Heavy Rain, Saturday)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _fillWeddingScenario,
                    child: const Text('Autofill'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Card
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
                    'EVENT PARAMETERS & ATTENDANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expectedPeopleController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Expected Guests',
                            prefixIcon: Icon(Icons.people_outline, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _plannedMealsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Planned Meals',
                            prefixIcon: Icon(Icons.restaurant_menu, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _currentAttendanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Attendance',
                            prefixIcon: Icon(Icons.how_to_reg_outlined, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _historicalRateController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Hist. Attendance Rate',
                            prefixIcon: Icon(Icons.history, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _eventType,
                          decoration:
                              const InputDecoration(labelText: 'Event Type'),
                          items: const [
                            DropdownMenuItem(value: 'wedding', child: Text('Wedding')),
                            DropdownMenuItem(value: 'banquet', child: Text('Banquet')),
                            DropdownMenuItem(value: 'conference', child: Text('Conference')),
                            DropdownMenuItem(
                                value: 'hostel_dinner', child: Text('Hostel Dinner')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _eventType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _menuCategory,
                          decoration:
                              const InputDecoration(labelText: 'Menu Category'),
                          items: const [
                            DropdownMenuItem(
                                value: 'vegetarian', child: Text('Vegetarian')),
                            DropdownMenuItem(
                                value: 'mixed', child: Text('Mixed / Non-Veg')),
                            DropdownMenuItem(value: 'buffet', child: Text('Buffet')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _menuCategory = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _weather,
                          decoration:
                              const InputDecoration(labelText: 'Weather Risk'),
                          items: const [
                            DropdownMenuItem(
                                value: 'heavy_rain', child: Text('Heavy Rain')),
                            DropdownMenuItem(
                                value: 'clear', child: Text('Clear / Pleasant')),
                            DropdownMenuItem(
                                value: 'extreme_heat', child: Text('Extreme Heat')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _weather = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _dayOfWeek,
                          decoration:
                              const InputDecoration(labelText: 'Day of Week'),
                          items: const [
                            DropdownMenuItem(
                                value: 'saturday', child: Text('Saturday')),
                            DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
                            DropdownMenuItem(value: 'friday', child: Text('Friday')),
                            DropdownMenuItem(
                                value: 'weekday', child: Text('Weekday')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _dayOfWeek = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Primary Action Obvious
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runSurplusPrediction,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.insights, size: 20),
                    label: Text(_isLoading
                        ? 'Computing ML Model...'
                        : 'Calculate AI Surplus Risk'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              ErrorStateCard(
                title: 'Prediction Error',
                message: _errorMessage!,
                onRetry: _runSurplusPrediction,
              ),
              const SizedBox(height: 20),
            ],

            // Result Display Card
            if (_predictionResult != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI PREDICTION INFERENCE RESULT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_predictionResult!.riskLevel.toUpperCase()} RISK',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Predicted Surplus',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_predictionResult!.predictedSurplus.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                ),
                              ),
                              Text(
                                '~ ${(_predictionResult!.predictedSurplus * 2).round()} Meals',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Model Confidence',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_predictionResult!.confidenceScore * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'RandomForest Model',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 14),
                    // Most Important Action Obvious: Find Matches
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '/sender/matching/${_predictionResult!.predictionId}',
                          extra: _predictionResult,
                        );
                      },
                      icon: const Icon(Icons.hub_rounded, size: 20),
                      label: const Text('Find Intelligent Recipient Matches'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
