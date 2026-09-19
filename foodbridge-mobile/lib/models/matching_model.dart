/// Matches FastAPI RecipientResponse schema
class RecipientSummary {
  final String id;
  final int? userId;
  final String organizationName;
  final String organizationType;
  final int peopleServed;
  final int currentDemand;
  final int maximumCapacity;
  final List<String> foodPreferences;
  final String availabilityStart;
  final String availabilityEnd;
  final double latitude;
  final double longitude;
  final String verificationStatus;

  const RecipientSummary({
    required this.id,
    this.userId,
    required this.organizationName,
    required this.organizationType,
    required this.peopleServed,
    required this.currentDemand,
    required this.maximumCapacity,
    required this.foodPreferences,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.latitude,
    required this.longitude,
    required this.verificationStatus,
  });

  factory RecipientSummary.fromJson(Map<String, dynamic> json) {
    var prefs = json['food_preferences'];
    List<String> prefList = [];
    if (prefs is List) {
      prefList = prefs.map((e) => e.toString()).toList();
    } else if (prefs is String) {
      prefList = prefs.split(',').map((e) => e.trim()).toList();
    }

    return RecipientSummary(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] as num?)?.toInt(),
      organizationName: json['organization_name']?.toString() ?? 'Community Recipient',
      organizationType: json['organization_type']?.toString() ?? 'Shelter',
      peopleServed: (json['people_served'] as num?)?.toInt() ?? 0,
      currentDemand: (json['current_demand'] as num?)?.toInt() ?? 0,
      maximumCapacity: (json['maximum_capacity'] as num?)?.toInt() ?? 0,
      foodPreferences: prefList,
      availabilityStart: json['availability_start']?.toString() ?? '09:00',
      availabilityEnd: json['availability_end']?.toString() ?? '22:00',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      verificationStatus: json['verification_status']?.toString() ?? 'VERIFIED',
    );
  }
}

/// Matches FastAPI MatchItem schema
class MatchResult {
  final RecipientSummary recipient;
  final double matchScore;
  final double distanceKm;
  final int currentDemand;
  final double compatibleQuantity;
  final String urgency;
  final String reason;

  const MatchResult({
    required this.recipient,
    required this.matchScore,
    required this.distanceKm,
    required this.currentDemand,
    required this.compatibleQuantity,
    required this.urgency,
    required this.reason,
  });

  /// Normalize score percentage whether represented as 0.0-1.0 or 0-100
  int get scorePercentage {
    if (matchScore > 1.0) {
      return matchScore.round().clamp(0, 100);
    }
    return (matchScore * 100).round().clamp(0, 100);
  }

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      recipient: RecipientSummary.fromJson(
        json['recipient'] as Map<String, dynamic>? ?? {},
      ),
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      currentDemand: (json['current_demand'] as num?)?.toInt() ?? 0,
      compatibleQuantity: (json['compatible_quantity'] as num?)?.toDouble() ?? 0.0,
      urgency: json['urgency']?.toString() ?? 'MEDIUM',
      reason: json['reason']?.toString() ?? 'Matched via FoodBridge Engine',
    );
  }
}

/// Matches FastAPI MatchingResponse schema
class MatchingResponse {
  final String predictionId;
  final String eventType;
  final String menuCategory;
  final String predictedSurplusRange;
  final double predictedSurplusAvg;
  final int totalMatches;
  final List<MatchResult> matches;

  const MatchingResponse({
    required this.predictionId,
    required this.eventType,
    required this.menuCategory,
    required this.predictedSurplusRange,
    required this.predictedSurplusAvg,
    required this.totalMatches,
    required this.matches,
  });

  factory MatchingResponse.fromJson(Map<String, dynamic> json) {
    final matchesRaw = json['matches'] as List<dynamic>? ?? [];
    return MatchingResponse(
      predictionId: json['prediction_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      menuCategory: json['menu_category']?.toString() ?? '',
      predictedSurplusRange: json['predicted_surplus_range']?.toString() ?? '',
      predictedSurplusAvg:
          (json['predicted_surplus_avg'] as num?)?.toDouble() ?? 0.0,
      totalMatches: (json['total_matches'] as num?)?.toInt() ?? matchesRaw.length,
      matches: matchesRaw
          .map((item) => MatchResult.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
