import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/impact_model.dart';

class ImpactService {
  final ApiClient _client;

  ImpactService(this._client);

  Future<ImpactSummary> getImpact() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.impactDashboard,
    );

    if (response.data == null) {
      return ImpactSummary.empty;
    }

    return ImpactSummary.fromJson(response.data!);
  }
}

final impactServiceProvider = Provider<ImpactService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ImpactService(client);
});

final impactSummaryProvider = FutureProvider.autoDispose<ImpactSummary>((ref) async {
  final service = ref.watch(impactServiceProvider);
  return await service.getImpact();
});
