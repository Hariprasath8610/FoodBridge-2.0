import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/matching_model.dart';

class MatchingService {
  final ApiClient _client;

  MatchingService(this._client);

  /// POST /api/matching/{prediction_id} - Evaluates & ranks verified recipients for predicted surplus
  Future<List<MatchResult>> getMatches(String predictionId) async {
    final response = await _client.post<dynamic>(
      ApiEndpoints.matching(predictionId),
    );

    if (response.data is Map<String, dynamic>) {
      final matchingResp =
          MatchingResponse.fromJson(response.data as Map<String, dynamic>);
      return matchingResp.matches;
    } else if (response.data is List) {
      return (response.data as List)
          .map((item) => MatchResult.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// GET /api/recipients - Lists verified welfare recipients
  Future<List<RecipientSummary>> getRecipients({String? verificationStatus}) async {
    final Map<String, dynamic> query = {};
    if (verificationStatus != null) {
      query['verification_status'] = verificationStatus;
    }

    final response = await _client.get<dynamic>(
      ApiEndpoints.recipients,
      queryParameters: query.isNotEmpty ? query : null,
    );

    if (response.data is List) {
      return (response.data as List)
          .map((item) => RecipientSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /api/recipients/demand - Updates recipient's live meal demand, capacity, and schedule
  Future<RecipientSummary> updateRecipientDemand({
    required int currentDemand,
    int? peopleServed,
    String? foodPreferences,
    String? availabilityStart,
    String? availabilityEnd,
  }) async {
    final Map<String, dynamic> body = {
      'current_demand': currentDemand,
    };
    if (peopleServed != null) body['people_served'] = peopleServed;
    if (foodPreferences != null) body['food_preferences'] = foodPreferences;
    if (availabilityStart != null) body['availability_start'] = availabilityStart;
    if (availabilityEnd != null) body['availability_end'] = availabilityEnd;

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.recipientDemand,
      data: body,
    );

    if (response.data == null) {
      throw ApiException(message: 'Failed to update recipient demand.');
    }

    return RecipientSummary.fromJson(response.data!);
  }

  /// GET /api/recipients/{id} - Fetches detailed recipient profile
  Future<RecipientSummary> getRecipientDetail(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiEndpoints.recipients}/$id',
    );
    if (response.data == null) {
      throw ApiException(message: 'Recipient profile not found.');
    }
    return RecipientSummary.fromJson(response.data!);
  }
}

final matchingServiceProvider = Provider<MatchingService>((ref) {
  final client = ref.watch(apiClientProvider);
  return MatchingService(client);
});
