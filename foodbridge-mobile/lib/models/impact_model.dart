/// Matches FastAPI DashboardImpactResponse schema
class ImpactSummary {
  final int totalMealsRescued;
  final int totalPeopleServed;
  final double totalFoodKgRescued;
  final double totalEstimatedValue;
  final int totalRescues;
  final Map<String, dynamic>? assumptions;

  const ImpactSummary({
    required this.totalMealsRescued,
    required this.totalPeopleServed,
    required this.totalFoodKgRescued,
    required this.totalEstimatedValue,
    required this.totalRescues,
    this.assumptions,
  });

  factory ImpactSummary.fromJson(Map<String, dynamic> json) {
    return ImpactSummary(
      totalMealsRescued: (json['total_meals_rescued'] as num?)?.toInt() ?? 0,
      totalPeopleServed: (json['total_people_served'] as num?)?.toInt() ?? 0,
      totalFoodKgRescued:
          (json['total_food_kg_rescued'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedValue:
          (json['total_estimated_value'] as num?)?.toDouble() ?? 0.0,
      totalRescues: (json['total_rescues'] as num?)?.toInt() ?? 0,
      assumptions: json['assumptions'] as Map<String, dynamic>?,
    );
  }

  static const ImpactSummary empty = ImpactSummary(
    totalMealsRescued: 0,
    totalPeopleServed: 0,
    totalFoodKgRescued: 0.0,
    totalEstimatedValue: 0.0,
    totalRescues: 0,
  );
}
