enum RescueStatus {
  created,
  recipientRequested,
  providerApproved,
  foodVerified,
  pickupReady,
  pickedUp,
  inTransit,
  delivered,
  cancelled;

  static RescueStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'RECIPIENT_REQUESTED':
        return RescueStatus.recipientRequested;
      case 'PROVIDER_APPROVED':
        return RescueStatus.providerApproved;
      case 'FOOD_VERIFIED':
        return RescueStatus.foodVerified;
      case 'PICKUP_READY':
        return RescueStatus.pickupReady;
      case 'PICKED_UP':
        return RescueStatus.pickedUp;
      case 'IN_TRANSIT':
        return RescueStatus.inTransit;
      case 'DELIVERED':
        return RescueStatus.delivered;
      case 'CANCELLED':
        return RescueStatus.cancelled;
      case 'CREATED':
      default:
        return RescueStatus.created;
    }
  }

  String get displayName {
    switch (this) {
      case RescueStatus.created:
        return 'Created';
      case RescueStatus.recipientRequested:
        return 'Requested';
      case RescueStatus.providerApproved:
        return 'Approved';
      case RescueStatus.foodVerified:
        return 'Food Verified';
      case RescueStatus.pickupReady:
        return 'Pickup Ready';
      case RescueStatus.pickedUp:
        return 'Picked Up';
      case RescueStatus.inTransit:
        return 'In Transit';
      case RescueStatus.delivered:
        return 'Delivered';
      case RescueStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case RescueStatus.created:
        return 0;
      case RescueStatus.recipientRequested:
        return 1;
      case RescueStatus.providerApproved:
        return 2;
      case RescueStatus.foodVerified:
        return 3;
      case RescueStatus.pickupReady:
        return 4;
      case RescueStatus.pickedUp:
        return 5;
      case RescueStatus.inTransit:
        return 6;
      case RescueStatus.delivered:
        return 7;
      case RescueStatus.cancelled:
        return -1;
    }
  }
}

/// Matches FastAPI RescueMissionResponse schema
class RescueMission {
  final String id;
  final String rescueCode;
  final String? predictionId;
  final String providerId;
  final String recipientId;
  final int? foodSourceId;
  final double quantity;
  final RescueStatus status;
  final String foodSafetyStatus;
  final String? pickupOtp;
  final String? deliveryOtp;
  final String? pickupTime;
  final String? deliveryTime;
  final String createdAt;
  final String? updatedAt;
  final String? providerName;
  final String? recipientName;

  const RescueMission({
    required this.id,
    required this.rescueCode,
    this.predictionId,
    required this.providerId,
    required this.recipientId,
    this.foodSourceId,
    required this.quantity,
    required this.status,
    required this.foodSafetyStatus,
    this.pickupOtp,
    this.deliveryOtp,
    this.pickupTime,
    this.deliveryTime,
    required this.createdAt,
    this.updatedAt,
    this.providerName,
    this.recipientName,
  });

  bool get isDelivered => status == RescueStatus.delivered;
  bool get isCancelled => status == RescueStatus.cancelled;
  bool get canApprove => status == RescueStatus.recipientRequested;
  bool get canVerifyFood => status == RescueStatus.providerApproved;
  bool get canPickup =>
      status == RescueStatus.foodVerified || status == RescueStatus.pickupReady;
  bool get canDeliver =>
      status == RescueStatus.pickedUp || status == RescueStatus.inTransit;

  factory RescueMission.fromJson(Map<String, dynamic> json) {
    return RescueMission(
      id: json['id']?.toString() ?? '',
      rescueCode: json['rescue_code']?.toString() ?? 'FB-MISSION',
      predictionId: json['prediction_id']?.toString(),
      providerId: json['provider_id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      foodSourceId: (json['food_source_id'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      status: RescueStatus.fromString(json['status']?.toString() ?? 'CREATED'),
      foodSafetyStatus: json['food_safety_status']?.toString() ?? 'PENDING',
      pickupOtp: json['pickup_otp']?.toString(),
      deliveryOtp: json['delivery_otp']?.toString(),
      pickupTime: json['pickup_time']?.toString(),
      deliveryTime: json['delivery_time']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
      providerName: json['provider_name']?.toString() ?? 'GreenLeaf Hotel',
      recipientName: json['recipient_name']?.toString() ?? 'Hope Community Kitchen',
    );
  }
}
