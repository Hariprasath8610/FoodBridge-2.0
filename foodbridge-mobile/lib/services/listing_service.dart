import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/food_listing_model.dart';

class ListingService {
  final ApiClient _client;

  ListingService(this._client);

  Future<List<FoodListingModel>> getListings({String status = 'AVAILABLE'}) async {
    final response = await _client.get<dynamic>(
      ApiEndpoints.listings,
      queryParameters: {'status': status},
    );

    if (response.data is List) {
      return (response.data as List)
          .map((item) => FoodListingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<FoodListingModel> getListing(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.listingDetail(id),
    );
    if (response.data == null) {
      throw ApiException(message: 'Surplus food listing not found.');
    }
    return FoodListingModel.fromJson(response.data!);
  }
}

final listingServiceProvider = Provider<ListingService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ListingService(client);
});

final availableListingsProvider =
    FutureProvider.autoDispose<List<FoodListingModel>>((ref) async {
  final service = ref.watch(listingServiceProvider);
  return await service.getListings();
});
