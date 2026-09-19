class ApiEndpoints {
  // Auth & Profile
  static const String me = '/api/me';

  // Predictions
  static const String predictions = '/api/predictions';
  static String predictionFeedback(String id) => '/api/predictions/$id/feedback';

  // Matching
  static String matching(String predictionId) => '/api/matching/$predictionId';

  // Rescues Lifecycle
  static const String rescues = '/api/rescues';
  static String rescueDetail(String id) => '/api/rescues/$id';
  static const String rescueRequest = '/api/rescues/request';
  static String rescueApprove(String id) => '/api/rescues/$id/approve';
  static String rescueVerifyFood(String id) => '/api/rescues/$id/verify-food';
  static String rescueVerifyPickup(String id) => '/api/rescues/$id/pickup/verify';
  static String rescueVerifyDelivery(String id) => '/api/rescues/$id/delivery/verify';
  static const String rescueVerifyQr = '/api/rescues/verify-qr';

  // Available Surplus Listings
  static const String listings = '/api/v1/listings';
  static String listingDetail(int id) => '/api/v1/listings/$id';

  // Impact Dashboard
  static const String impactDashboard = '/api/dashboard/impact';

  // Recipients
  static const String recipients = '/api/recipients';
  static const String recipientDemand = '/api/recipients/demand';
}
