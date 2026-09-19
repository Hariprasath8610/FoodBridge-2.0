enum UserRole {
  sender,
  recipient;

  static UserRole fromString(String value) {
    return value.toLowerCase() == 'recipient' ? UserRole.recipient : UserRole.sender;
  }

  String get displayName => this == UserRole.sender ? 'Food Provider' : 'Food Recipient';
}

/// Matches FastAPI UserMeResponse & UserResponse schemas
class UserModel {
  final String id;
  final String firebaseUid;
  final String email;
  final String organizationName;
  final String organizationType;
  final UserRole role;
  final String verificationStatus;
  final String? phone;
  final double? latitude;
  final double? longitude;

  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.organizationName,
    required this.organizationType,
    required this.role,
    required this.verificationStatus,
    this.phone,
    this.latitude,
    this.longitude,
  });

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isSender => role == UserRole.sender;
  bool get isRecipient => role == UserRole.recipient;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firebaseUid: json['firebase_uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      organizationName: json['organization_name']?.toString() ?? 'FoodBridge Partner',
      organizationType: json['organization_type']?.toString() ?? 'Organization',
      role: UserRole.fromString(json['role']?.toString() ?? 'sender'),
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      phone: json['phone']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'organization_name': organizationName,
      'organization_type': organizationType,
      'role': role.name,
      'verification_status': verificationStatus,
      if (phone != null) 'phone': phone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
