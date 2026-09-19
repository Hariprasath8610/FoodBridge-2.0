import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/rescue_model.dart';

class RescueService {
  final ApiClient _client;

  RescueService(this._client);

  /// GET /api/rescues - Lists missions accessible to the authenticated user
  Future<List<RescueMission>> getRescues({String? status}) async {
    final Map<String, dynamic> query = {};
    if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
      query['status'] = status.toUpperCase();
    }

    final response = await _client.get<dynamic>(
      ApiEndpoints.rescues,
      queryParameters: query.isNotEmpty ? query : null,
    );

    if (response.data is List) {
      return (response.data as List)
          .map((item) => RescueMission.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /api/rescues/{id} - Fetches single mission details
  Future<RescueMission> getRescue(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.rescueDetail(id),
    );
    if (response.data == null) {
      throw ApiException(message: 'Mission not found.');
    }
    return RescueMission.fromJson(response.data!);
  }

  /// POST /api/rescues/request - Recipient requests a surplus food opportunity
  Future<RescueMission> requestFood({
    int providerId = 1,
    required double quantity,
    String? predictionId,
    int? foodSourceId,
  }) async {
    final Map<String, dynamic> body = {
      'provider_id': providerId,
      'quantity': quantity.round().clamp(1, 10000),
    };
    if (predictionId != null && predictionId.isNotEmpty) {
      body['prediction_id'] = predictionId;
    }
    if (foodSourceId != null) {
      body['food_source_id'] = foodSourceId;
    }

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.rescueRequest,
      data: body,
    );
    if (response.data == null) {
      throw ApiException(message: 'Failed to request food rescue.');
    }
    return RescueMission.fromJson(response.data!);
  }

  /// POST /api/rescues/{id}/approve - Provider approves requested mission
  Future<RescueMission> approveRescue(String id) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.rescueApprove(id),
    );
    if (response.data == null) {
      throw ApiException(message: 'Failed to approve rescue.');
    }
    return RescueMission.fromJson(response.data!);
  }

  /// POST /api/rescues/{id}/verify-food - Provider certifies food safety and packaging
  Future<RescueMission> verifyFood(
    String id, {
    bool passesHygiene = true,
    double? temperatureC,
    String? notes,
  }) async {
    final Map<String, dynamic> body = {
      'safety_status': passesHygiene ? 'SAFE_VERIFIED' : 'UNSAFE_REJECTED',
      'notes': notes ?? 'Hygienically prepared and temperature verified.',
    };
    if (temperatureC != null) {
      body['temperature_c'] = temperatureC;
    }

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.rescueVerifyFood(id),
      data: body,
    );
    if (response.data == null) {
      throw ApiException(message: 'Failed to verify food safety.');
    }
    return RescueMission.fromJson(response.data!);
  }

  /// POST /api/rescues/{id}/pickup/verify - Verifies pickup handoff
  Future<RescueMission> verifyPickup(
    String id, {
    String? otp,
    String? rescueCode,
    String? qrData,
  }) async {
    final Map<String, dynamic> body = {};
    if (otp != null && otp.isNotEmpty) body['pickup_otp'] = otp.trim();
    if (rescueCode != null && rescueCode.isNotEmpty) {
      body['rescue_code'] = rescueCode.trim();
    }
    if (qrData != null && qrData.isNotEmpty) {
      body['qr_data'] = qrData.trim();
    }

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.rescueVerifyPickup(id),
      data: body,
    );
    if (response.data == null) {
      throw ApiException(message: 'Invalid pickup verification code.');
    }
    return RescueMission.fromJson(response.data!);
  }

  /// POST /api/rescues/{id}/delivery/verify - Recipient confirms delivery receipt
  Future<RescueMission> verifyDelivery(
    String id, {
    String? otp,
    String? rescueCode,
    String? qrData,
  }) async {
    final Map<String, dynamic> body = {};
    if (otp != null && otp.isNotEmpty) body['delivery_otp'] = otp.trim();
    if (rescueCode != null && rescueCode.isNotEmpty) {
      body['rescue_code'] = rescueCode.trim();
    }
    if (qrData != null && qrData.isNotEmpty) {
      body['qr_data'] = qrData.trim();
    }

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.rescueVerifyDelivery(id),
      data: body,
    );
    if (response.data == null) {
      throw ApiException(message: 'Invalid delivery verification code.');
    }
    return RescueMission.fromJson(response.data!);
  }

  /// POST /api/rescues/verify-qr - Safe QR code scanner handler
  Future<RescueMission> verifyQr({
    required String qrData,
    String? action,
    int? rescueId,
  }) async {
    final Map<String, dynamic> body = {
      'qr_data': qrData.trim(),
    };
    if (action != null) body['action'] = action;
    if (rescueId != null) body['rescue_id'] = rescueId;

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.rescueVerifyQr,
      data: body,
    );
    if (response.data == null) {
      throw ApiException(message: 'Failed to verify QR rescue mission.');
    }
    return RescueMission.fromJson(response.data!);
  }
}

final rescueServiceProvider = Provider<RescueService>((ref) {
  final client = ref.watch(apiClientProvider);
  return RescueService(client);
});

// Auto-refreshing rescue missions list provider
final activeRescuesProvider =
    FutureProvider.autoDispose<List<RescueMission>>((ref) async {
  final service = ref.watch(rescueServiceProvider);
  return await service.getRescues();
});
