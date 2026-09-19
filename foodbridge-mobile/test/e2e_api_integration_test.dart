import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge_mobile/core/config/app_config.dart';
import 'package:foodbridge_mobile/models/prediction_model.dart';
import 'package:foodbridge_mobile/models/rescue_model.dart';
import 'package:foodbridge_mobile/models/user_model.dart';
import 'package:foodbridge_mobile/services/auth_service.dart';
import 'package:foodbridge_mobile/services/impact_service.dart';
import 'package:foodbridge_mobile/services/matching_service.dart';
import 'package:foodbridge_mobile/services/prediction_service.dart';
import 'package:foodbridge_mobile/services/rescue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpOverrides.global = null;
    final client = HttpClient(context: context);
    HttpOverrides.global = this;
    return client;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = RealHttpOverrides();

  group('Live FoodBridge FastAPI Backend Integration Tests', () {
    late ProviderContainer container;

    setUp(() async {
      HttpOverrides.global = RealHttpOverrides();
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      // Configure base URL to local running FastAPI server on port 8000
      await container
          .read(serverConfigProvider.notifier)
          .updateBaseUrl('http://127.0.0.1:8000');
    });

    tearDown(() {
      container.dispose();
    });

    test('Full End-to-End Workflow with live FastAPI server', () async {
      // 1. Authenticate Provider
      const providerToken =
          'test-firebase-sender-hotel-1:hotel@greenleaf.demo';
      final providerLoginSuccess = await container
          .read(authServiceProvider.notifier)
          .loginWithToken(providerToken);

      expect(providerLoginSuccess, isTrue);
      final providerUser = container.read(authServiceProvider).user;
      expect(providerUser, isNotNull);
      expect(providerUser!.organizationName, equals('GreenLeaf Hotel'));
      expect(providerUser.role, equals(UserRole.sender));
      expect(providerUser.isVerified, isTrue);

      // 2. Provider creates Prediction: POST /api/predictions
      final predictionService = container.read(predictionServiceProvider);
      final predictionReq = PredictionRequest(
        expectedPeople: 500,
        plannedQuantity: 500,
        historicalAttendanceRate: 0.92,
        currentAttendance: 430,
        eventType: 'wedding',
        menuCategory: 'vegetarian',
        weatherCondition: 'heavy_rain',
        dayOfWeek: 'saturday',
        historicalSurplusRate: 0.08,
      );

      final prediction =
          await predictionService.createPrediction(predictionReq);
      expect(prediction.predictionId, isNotEmpty);
      expect(prediction.predictedConsumption, greaterThan(300.0));
      expect(prediction.predictedSurplus, greaterThan(0.0));
      expect(prediction.factors, isNotEmpty);

      // 3. Provider finds Matches: POST /api/matching/{prediction_id}
      final matchingService = container.read(matchingServiceProvider);
      final matches =
          await matchingService.getMatches(prediction.predictionId);
      expect(matches, isNotEmpty);
      expect(matches.first.recipient.organizationName,
          equals('Hope Community Kitchen'));
      expect(matches.first.scorePercentage, greaterThan(50));

      // 4. Authenticate Recipient
      const recipientToken =
          'test-firebase-recipient-kitchen-1:contact@hopekitchen.demo';
      final recipientLoginSuccess = await container
          .read(authServiceProvider.notifier)
          .loginWithToken(recipientToken);

      expect(recipientLoginSuccess, isTrue);
      final recipientUser = container.read(authServiceProvider).user;
      expect(recipientUser, isNotNull);
      expect(
          recipientUser!.organizationName, equals('Hope Community Kitchen'));
      expect(recipientUser.role, equals(UserRole.recipient));

      // 5. Recipient updates Demand: POST /api/recipients/demand
      final updatedRecipient = await matchingService.updateRecipientDemand(
        currentDemand: 160,
        peopleServed: 270,
        foodPreferences: 'all',
        availabilityStart: '07:00',
        availabilityEnd: '23:00',
      );
      expect(updatedRecipient.currentDemand, equals(160));
      expect(updatedRecipient.peopleServed, equals(270));

      // 6. Recipient requests food: POST /api/rescues/request
      final rescueService = container.read(rescueServiceProvider);
      final mission = await rescueService.requestFood(
        providerId: int.parse(providerUser.id),
        quantity: 80.0,
        predictionId: prediction.predictionId,
      );
      expect(mission.id, isNotEmpty);
      expect(mission.status, equals(RescueStatus.recipientRequested));
      expect(mission.rescueCode, startsWith('RESCUE-'));

      // 7. Provider approves rescue: POST /api/rescues/{id}/approve
      // Switch auth back to provider
      await container
          .read(authServiceProvider.notifier)
          .loginWithToken(providerToken);

      final approvedMission = await rescueService.approveRescue(mission.id);
      expect(approvedMission.status, equals(RescueStatus.providerApproved));

      // 8. Provider certifies food safety: POST /api/rescues/{id}/verify-food
      final verifiedMission = await rescueService.verifyFood(
        mission.id,
        passesHygiene: true,
        temperatureC: 69.0,
        notes: 'Insulated packaging verified.',
      );
      expect(verifiedMission.status, equals(RescueStatus.foodVerified));
      expect(verifiedMission.foodSafetyStatus, equals('SAFE_VERIFIED'));

      // 9. Pickup verification: POST /api/rescues/{id}/pickup/verify
      final inTransitMission = await rescueService.verifyPickup(
        mission.id,
        otp: verifiedMission.pickupOtp,
      );
      expect(inTransitMission.status, equals(RescueStatus.inTransit));

      // 10. Delivery verification: POST /api/rescues/{id}/delivery/verify
      // Switch auth to recipient
      await container
          .read(authServiceProvider.notifier)
          .loginWithToken(recipientToken);

      final deliveredMission = await rescueService.verifyDelivery(
        mission.id,
        otp: inTransitMission.deliveryOtp,
      );
      expect(deliveredMission.status, equals(RescueStatus.delivered));

      // 11. Prediction Feedback: POST /api/predictions/{id}/feedback
      final feedback = await predictionService.submitFeedback(
        predictionId: prediction.predictionId,
        predictedQuantity: prediction.predictedSurplus,
        actualQuantity: 80.0,
      );
      expect(feedback.predictionId, equals(prediction.predictionId));
      expect(feedback.feedbackStatus, equals('STORED'));

      // 12. Impact Dashboard: GET /api/dashboard/impact
      final impactService = container.read(impactServiceProvider);
      final impact = await impactService.getImpact();
      expect(impact.totalMealsRescued, greaterThan(0));
      expect(impact.totalRescues, greaterThan(0));

      // 13. Rescues List & Detail: GET /api/rescues, GET /api/rescues/{id}
      final allRescues = await rescueService.getRescues();
      expect(allRescues, isNotEmpty);
      final singleMission = await rescueService.getRescue(mission.id);
      expect(singleMission.id, equals(mission.id));
      expect(singleMission.status, equals(RescueStatus.delivered));
    });
  });
}
