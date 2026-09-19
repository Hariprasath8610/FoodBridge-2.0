class PredictionFactor {
  final String factor;
  final String effect;
  final String description;

  const PredictionFactor({
    required this.factor,
    required this.effect,
    required this.description,
  });

  factory PredictionFactor.fromJson(Map<String, dynamic> json) {
    return PredictionFactor(
      factor: json['factor']?.toString() ?? '',
      effect: json['effect']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'factor': factor,
        'effect': effect,
        'description': description,
      };
}

/// Matches FastAPI PredictionRequest schema
class PredictionRequest {
  final int expectedPeople;
  final double plannedQuantity;
  final double historicalAttendanceRate;
  final int currentAttendance;
  final String eventType;
  final String menuCategory;
  final String weatherCondition;
  final String dayOfWeek;
  final double historicalSurplusRate;

  const PredictionRequest({
    required this.expectedPeople,
    required this.plannedQuantity,
    required this.historicalAttendanceRate,
    required this.currentAttendance,
    required this.eventType,
    required this.menuCategory,
    required this.weatherCondition,
    required this.dayOfWeek,
    required this.historicalSurplusRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'expected_people': expectedPeople,
      'planned_quantity': plannedQuantity.round(),
      'historical_attendance_rate': historicalAttendanceRate,
      'current_attendance': currentAttendance,
      'event_type': eventType,
      'menu_category': menuCategory,
      'weather_condition': weatherCondition,
      'day_of_week': dayOfWeek,
      'historical_surplus_rate': historicalSurplusRate,
    };
  }
}

/// Matches FastAPI PredictionResponse schema
class PredictionResponse {
  final String predictionId;
  final double predictedConsumption;
  final double predictedSurplusMin;
  final double predictedSurplusMax;
  final double surplusPercentage;
  final String riskLevel;
  final String explanation;
  final List<PredictionFactor> factors;
  final double confidenceScore;
  final String createdAt;

  const PredictionResponse({
    required this.predictionId,
    required this.predictedConsumption,
    required this.predictedSurplusMin,
    required this.predictedSurplusMax,
    required this.surplusPercentage,
    required this.riskLevel,
    required this.explanation,
    required this.factors,
    this.confidenceScore = 0.88,
    required this.createdAt,
  });

  /// Computed average surplus for display and mission dispatch
  double get predictedSurplus =>
      (predictedSurplusMin + predictedSurplusMax) / 2.0;

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    final minSurplus =
        (json['predicted_surplus_min'] as num?)?.toDouble() ?? 0.0;
    final maxSurplus =
        (json['predicted_surplus_max'] as num?)?.toDouble() ?? minSurplus;

    final factorsRaw = json['factors'];
    List<PredictionFactor> factorList = [];
    if (factorsRaw is List) {
      factorList = factorsRaw
          .map((f) => PredictionFactor.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    return PredictionResponse(
      predictionId: json['prediction_id']?.toString() ?? '',
      predictedConsumption:
          (json['predicted_consumption'] as num?)?.toDouble() ?? 0.0,
      predictedSurplusMin: minSurplus,
      predictedSurplusMax: maxSurplus,
      surplusPercentage:
          (json['surplus_percentage'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level']?.toString() ?? 'MEDIUM',
      explanation: json['explanation']?.toString() ?? '',
      factors: factorList,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.88,
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

/// Matches FastAPI PredictionFeedbackRequest & PredictionFeedbackResponse schemas
class PredictionFeedbackResponse {
  final String predictionId;
  final double predictedQuantity;
  final double actualQuantity;
  final double absoluteError;
  final double percentageError;
  final String feedbackStatus;
  final String message;

  const PredictionFeedbackResponse({
    required this.predictionId,
    required this.predictedQuantity,
    required this.actualQuantity,
    required this.absoluteError,
    required this.percentageError,
    required this.feedbackStatus,
    required this.message,
  });

  factory PredictionFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return PredictionFeedbackResponse(
      predictionId: json['prediction_id']?.toString() ?? '',
      predictedQuantity:
          (json['predicted_quantity'] as num?)?.toDouble() ?? 0.0,
      actualQuantity: (json['actual_quantity'] as num?)?.toDouble() ?? 0.0,
      absoluteError: (json['absolute_error'] as num?)?.toDouble() ?? 0.0,
      percentageError: (json['percentage_error'] as num?)?.toDouble() ?? 0.0,
      feedbackStatus: json['feedback_status']?.toString() ?? 'STORED',
      message: json['message']?.toString() ??
          'Actual surplus feedback recorded for future AI model fine-tuning.',
    );
  }
}
