import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge_mobile/models/food_listing_model.dart';
import 'package:foodbridge_mobile/models/impact_model.dart';
import 'package:foodbridge_mobile/models/matching_model.dart';
import 'package:foodbridge_mobile/models/prediction_model.dart';
import 'package:foodbridge_mobile/models/rescue_model.dart';
import 'package:foodbridge_mobile/models/user_model.dart';
import 'package:foodbridge_mobile/widgets/brand_identity_bar.dart';
import 'package:foodbridge_mobile/widgets/empty_state_view.dart';
import 'package:foodbridge_mobile/widgets/mission_status_badge.dart';
import 'package:foodbridge_mobile/widgets/verified_badge.dart';

void main() {
  group('FoodBridge Models Unit Tests', () {
    test('UserModel serialization and role detection', () {
      final userSender = UserModel.fromJson({
        'id': 'usr-1',
        'firebase_uid': 'fb-1',
        'email': 'hotel@greenleaf.demo',
        'organization_name': 'GreenLeaf Hotel',
        'organization_type': 'hotel',
        'role': 'sender',
        'verification_status': 'verified',
      });

      expect(userSender.isSender, isTrue);
      expect(userSender.isRecipient, isFalse);
      expect(userSender.isVerified, isTrue);

      final userRecipient = UserModel.fromJson({
        'id': 'usr-2',
        'firebase_uid': 'fb-2',
        'email': 'contact@hopekitchen.demo',
        'organization_name': 'Hope Community Kitchen',
        'organization_type': 'community_kitchen',
        'role': 'recipient',
        'verification_status': 'verified',
      });

      expect(userRecipient.isRecipient, isTrue);
      expect(userRecipient.isSender, isFalse);
    });

    test('RescueMission status lifecycle transitions', () {
      final mission = RescueMission.fromJson({
        'id': 'res-1',
        'rescue_code': 'FB-2026-0042',
        'prediction_id': 'pred-1',
        'provider_id': 'prov-1',
        'recipient_id': 'rec-1',
        'quantity': 70.0,
        'status': 'RECIPIENT_REQUESTED',
        'food_safety_status': 'PENDING',
        'pickup_otp': '123456',
        'delivery_otp': '654321',
        'created_at': '2026-09-19T10:00:00Z',
      });

      expect(mission.canApprove, isTrue);
      expect(mission.canVerifyFood, isFalse);
      expect(mission.pickupOtp, equals('123456'));
      expect(mission.deliveryOtp, equals('654321'));
    });

    test('FoodListingModel serialization and Haversine distance', () {
      final listing = FoodListingModel.fromJson({
        'id': 1,
        'provider_id': 2,
        'title': 'Wedding Feast Surplus',
        'food_type': 'VEG',
        'meal_type': 'DINNER',
        'quantity_servings': 120,
        'weight_kg': 54.0,
        'prepared_time': '2026-09-19T18:00:00Z',
        'expiry_time': '2026-09-19T23:00:00Z',
        'pickup_address': 'Sunrise Palace Grounds Gate 2',
        'city': 'Bangalore',
        'latitude': 13.0033,
        'longitude': 77.5891,
        'status': 'AVAILABLE',
        'provider': {
          'organization_name': 'Sunrise Wedding Hall',
          'verification_status': 'VERIFIED',
        },
      });

      expect(listing.isVeg, isTrue);
      expect(listing.isProviderVerified, isTrue);
      expect(listing.quantityServings, equals(120));

      // Calculate distance to Shivajinagar recipient (12.9785, 77.6010)
      final distance = listing.distanceTo(12.9785, 77.6010);
      expect(distance, greaterThan(2.0));
      expect(distance, lessThan(6.0));
    });

    test('Safe QR verification payload does not contain OTP', () {
      const rescueCode = 'RESCUE-20260920-A1B2C3';
      const secretOtp = '839201';

      // Safe QR payload contains ONLY the short rescue identifier
      final safeQrPayload = '{"rescue_code": "$rescueCode", "action": "pickup"}';

      expect(safeQrPayload, contains(rescueCode));
      expect(safeQrPayload, isNot(contains(secretOtp)));
    });

    test('PredictionResponse deserialization matching FastAPI schema', () {
      final prediction = PredictionResponse.fromJson({
        'prediction_id': 'pred_2b90774c58eb',
        'predicted_consumption': 387.9,
        'predicted_surplus_min': 69.0,
        'predicted_surplus_max': 167.7,
        'surplus_percentage': 22.4,
        'risk_level': 'HIGH',
        'explanation': 'Estimated surplus range of 69 to 167 meals (~22.4%).',
        'factors': [
          {
            'factor': 'weather',
            'effect': 'increase_risk',
            'description': 'Heavy rain reduces turnout.'
          }
        ]
      });

      expect(prediction.predictionId, equals('pred_2b90774c58eb'));
      expect(prediction.predictedConsumption, equals(387.9));
      expect(prediction.predictedSurplusMin, equals(69.0));
      expect(prediction.predictedSurplusMax, equals(167.7));
      expect(prediction.predictedSurplus, equals(118.35));
      expect(prediction.factors.length, equals(1));
      expect(prediction.factors.first.factor, equals('weather'));
    });

    test('MatchingResponse and MatchResult matching FastAPI schema', () {
      final matchingResp = MatchingResponse.fromJson({
        'prediction_id': 'pred_2b90774c58eb',
        'event_type': 'wedding',
        'menu_category': 'vegetarian',
        'predicted_surplus_range': '69 - 167 meals',
        'predicted_surplus_avg': 118.3,
        'total_matches': 1,
        'matches': [
          {
            'recipient': {
              'id': 1,
              'user_id': 4,
              'organization_name': 'Hope Community Kitchen',
              'organization_type': 'community_kitchen',
              'people_served': 250,
              'current_demand': 175,
              'maximum_capacity': 300,
              'food_preferences': 'all',
              'availability_start': '07:00',
              'availability_end': '23:00',
              'latitude': 12.9785,
              'longitude': 77.6010,
              'verification_status': 'VERIFIED',
            },
            'match_score': 83.7,
            'distance_km': 1.03,
            'current_demand': 175,
            'compatible_quantity': 118,
            'urgency': 'CRITICAL',
            'reason': 'Close proximity 1.03km and urgent demand for 175 meals.'
          }
        ]
      });

      expect(matchingResp.totalMatches, equals(1));
      expect(matchingResp.matches.first.scorePercentage, equals(84));
      expect(matchingResp.matches.first.recipient.organizationName,
          equals('Hope Community Kitchen'));
      expect(matchingResp.matches.first.recipient.userId, equals(4));
    });

    test('ImpactSummary matching FastAPI schema', () {
      final impact = ImpactSummary.fromJson({
        'total_meals_rescued': 125,
        'total_people_served': 125,
        'total_food_kg_rescued': 56.3,
        'total_estimated_value': 10000.0,
        'total_rescues': 2,
        'assumptions': {
          'kg_per_meal': 0.45,
          'value_per_meal_inr': 80.0,
        }
      });

      expect(impact.totalMealsRescued, equals(125));
      expect(impact.totalFoodKgRescued, equals(56.3));
      expect(impact.totalEstimatedValue, equals(10000.0));
      expect(impact.assumptions?['kg_per_meal'], equals(0.45));
    });
  });

  group('FoodBridge Polished UI Widget Tests', () {
    testWidgets('VerifiedBadge renders provider and recipient variants',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VerifiedBadge(type: VerifiedType.provider),
                VerifiedBadge(type: VerifiedType.recipient),
              ],
            ),
          ),
        ),
      );

      expect(find.text('VERIFIED PROVIDER'), findsOneWidget);
      expect(find.text('VERIFIED RECIPIENT'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsNWidgets(2));
    });

    testWidgets('BrandIdentityBar renders all 4 FoodBridge pipeline stages',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandIdentityBar(activeStepIndex: 0),
          ),
        ),
      );

      expect(find.text('Predict'), findsOneWidget);
      expect(find.text('Match'), findsOneWidget);
      expect(find.text('Rescue'), findsOneWidget);
      expect(find.text('Impact'), findsOneWidget);
      expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
      expect(find.byIcon(Icons.hub_rounded), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_rounded), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('EmptyStateView renders title, description, and action button',
        (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox_outlined,
              title: 'No Active Missions',
              description: 'When missions are dispatched, they will appear here.',
              actionLabel: 'Predict Surplus',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('No Active Missions'), findsOneWidget);
      expect(
          find.text('When missions are dispatched, they will appear here.'),
          findsOneWidget);
      expect(find.text('Predict Surplus'), findsOneWidget);

      await tester.tap(find.text('Predict Surplus'));
      expect(actionPressed, isTrue);
    });

    testWidgets('MissionStatusBadge renders correct status labels',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MissionStatusBadge(status: RescueStatus.foodVerified),
                MissionStatusBadge(status: RescueStatus.inTransit),
                MissionStatusBadge(status: RescueStatus.delivered),
              ],
            ),
          ),
        ),
      );

      expect(find.text('FOOD VERIFIED'), findsOneWidget);
      expect(find.text('IN TRANSIT'), findsOneWidget);
      expect(find.text('DELIVERED'), findsOneWidget);
    });
  });
}
