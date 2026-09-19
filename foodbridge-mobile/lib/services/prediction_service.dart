import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/prediction_model.dart';

class PredictionService {
  final ApiClient _client;

  PredictionService(this._client);

  /// POST /api/predictions - Generates ML prediction and returns uncertainty bounds + factors
  Future<PredictionResponse> createPrediction(PredictionRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.predictions,
      data: request.toJson(),
    );

    if (response.data == null) {
      throw ApiException(message: 'Empty response received from prediction API.');
    }

    return PredictionResponse.fromJson(response.data!);
  }

  /// POST /api/predictions/{id}/feedback - Records actual surplus feedback for continuous AI learning
  Future<PredictionFeedbackResponse> submitFeedback({
    required String predictionId,
    required double predictedQuantity,
    required double actualQuantity,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.predictionFeedback(predictionId),
      data: {
        'predicted_quantity': predictedQuantity,
        'actual_quantity': actualQuantity,
      },
    );

    if (response.data == null) {
      throw ApiException(message: 'Failed to record prediction feedback.');
    }

    return PredictionFeedbackResponse.fromJson(response.data!);
  }
}

final predictionServiceProvider = Provider<PredictionService>((ref) {
  final client = ref.watch(apiClientProvider);
  return PredictionService(client);
});
