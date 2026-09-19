import 'dart:math';

class FoodListingModel {
  final int id;
  final int providerId;
  final String title;
  final String? description;
  final String foodType; // VEG, NON_VEG, BOTH
  final String mealType; // BREAKFAST, LUNCH, DINNER, SNACKS
  final int quantityServings;
  final double weightKg;
  final String preparedTime;
  final String expiryTime;
  final String pickupAddress;
  final String city;
  final double latitude;
  final double longitude;
  final String status;
  final String providerName;
  final String providerVerificationStatus;

  const FoodListingModel({
    required this.id,
    required this.providerId,
    required this.title,
    this.description,
    required this.foodType,
    required this.mealType,
    required this.quantityServings,
    required this.weightKg,
    required this.preparedTime,
    required this.expiryTime,
    required this.pickupAddress,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.providerName,
    required this.providerVerificationStatus,
  });

  bool get isVeg => foodType.toUpperCase() == 'VEG';
  bool get isNonVeg => foodType.toUpperCase() == 'NON_VEG';
  bool get isProviderVerified =>
      providerVerificationStatus.toUpperCase() == 'VERIFIED';

  double distanceTo(double recipientLat, double recipientLng) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((recipientLat - latitude) * p) / 2 +
        cos(latitude * p) *
            cos(recipientLat * p) *
            (1 - cos((recipientLng - longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  factory FoodListingModel.fromJson(Map<String, dynamic> json) {
    final providerJson = json['provider'] as Map<String, dynamic>?;

    return FoodListingModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      providerId: (json['provider_id'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? 'Surplus Food Batch',
      description: json['description']?.toString(),
      foodType: json['food_type']?.toString() ?? 'VEG',
      mealType: json['meal_type']?.toString() ?? 'LUNCH',
      quantityServings: (json['quantity_servings'] as num?)?.toInt() ?? 50,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 25.0,
      preparedTime: json['prepared_time']?.toString() ?? '',
      expiryTime: json['expiry_time']?.toString() ?? '',
      pickupAddress: json['pickup_address']?.toString() ?? 'Provider Facility',
      city: json['city']?.toString() ?? 'Bangalore',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 12.9716,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.5946,
      status: json['status']?.toString() ?? 'AVAILABLE',
      providerName: providerJson?['organization_name']?.toString() ??
          'GreenLeaf Hotel',
      providerVerificationStatus:
          providerJson?['verification_status']?.toString() ?? 'VERIFIED',
    );
  }
}
