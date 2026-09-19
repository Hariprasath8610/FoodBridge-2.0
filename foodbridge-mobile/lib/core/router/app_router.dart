import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/recipient/delivery_confirmation_screen.dart';
import '../../features/recipient/recipient_shell_screen.dart';
import '../../features/recipient/recipient_demand_screen.dart';
import '../../features/recipient/recipient_mission_detail_screen.dart';
import '../../features/sender/food_safety_screen.dart';
import '../../features/sender/matching_results_screen.dart';
import '../../features/sender/pickup_verification_screen.dart';
import '../../features/sender/predict_surplus_screen.dart';
import '../../features/sender/prediction_feedback_screen.dart';
import '../../features/sender/sender_dashboard_screen.dart';
import '../../features/sender/sender_mission_detail_screen.dart';
import '../../models/prediction_model.dart';
import '../../models/rescue_model.dart';
import '../../services/auth_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authServiceProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthStateListenable(authNotifier),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authServiceProvider);
      final isAuth = authState.isAuthenticated;
      final isSender = authState.isSender;
      final isRecipient = authState.isRecipient;

      final loc = state.matchedLocation;

      // Allow splash to perform initial checks
      if (loc == '/splash') return null;

      // Unauthenticated access restrictions
      if (!isAuth) {
        if (loc.startsWith('/sender') || loc.startsWith('/recipient')) {
          return '/login';
        }
        return null;
      }

      // Authenticated users should not revisit login/register
      if (loc == '/login' || loc == '/register') {
        return isSender ? '/sender/dashboard' : '/recipient/dashboard';
      }

      // Strict role-based guard: prevent Provider from accessing Recipient routes & vice versa
      if (isSender && loc.startsWith('/recipient')) {
        return '/sender/dashboard';
      }
      if (isRecipient && loc.startsWith('/sender')) {
        return '/recipient/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // SENDER (FOOD PROVIDER - PHONE 1)
      GoRoute(
        path: '/sender/dashboard',
        builder: (context, state) => const SenderDashboardScreen(),
      ),
      GoRoute(
        path: '/sender/predict',
        builder: (context, state) => const PredictSurplusScreen(),
      ),
      GoRoute(
        path: '/sender/matching/:predictionId',
        builder: (context, state) {
          final id = state.pathParameters['predictionId'] ?? '';
          final extra = state.extra as PredictionResponse?;
          return MatchingResultsScreen(predictionId: id, prediction: extra);
        },
      ),
      GoRoute(
        path: '/sender/mission/:missionId',
        builder: (context, state) {
          final id = state.pathParameters['missionId'] ?? '';
          return SenderMissionDetailScreen(missionId: id);
        },
      ),
      GoRoute(
        path: '/sender/mission/:missionId/verify-food',
        builder: (context, state) {
          final id = state.pathParameters['missionId'] ?? '';
          return FoodSafetyScreen(missionId: id);
        },
      ),
      GoRoute(
        path: '/sender/mission/:missionId/pickup',
        builder: (context, state) {
          final mission = state.extra as RescueMission;
          return PickupVerificationScreen(mission: mission);
        },
      ),
      GoRoute(
        path: '/sender/feedback/:predictionId',
        builder: (context, state) {
          final id = state.pathParameters['predictionId'] ?? '';
          final mission = state.extra as RescueMission?;
          return PredictionFeedbackScreen(predictionId: id, mission: mission);
        },
      ),

      // RECIPIENT (FOOD RECIPIENT - PHONE 2)
      GoRoute(
        path: '/recipient/dashboard',
        builder: (context, state) => const RecipientShellScreen(),
      ),
      GoRoute(
        path: '/recipient/mission/:missionId',
        builder: (context, state) {
          final id = state.pathParameters['missionId'] ?? '';
          return RecipientMissionDetailScreen(missionId: id);
        },
      ),
      GoRoute(
        path: '/recipient/mission/:missionId/deliver',
        builder: (context, state) {
          final mission = state.extra as RescueMission;
          return DeliveryConfirmationScreen(mission: mission);
        },
      ),
      GoRoute(
        path: '/recipient/demand',
        builder: (context, state) => const RecipientDemandScreen(),
      ),
    ],
  );
});

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(StateNotifier<AuthState> notifier) {
    notifier.addListener((_) => notifyListeners());
  }
}
