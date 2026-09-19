import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? token;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;
  bool get isSender => user?.isSender ?? false;
  bool get isRecipient => user?.isRecipient ?? false;

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
    );
  }
}

class AuthService extends StateNotifier<AuthState> {
  static const String _tokenPrefKey = 'foodbridge_auth_token';
  static const String _userPrefKey = 'foodbridge_user_profile';

  final Ref _ref;

  AuthService(this._ref) : super(const AuthState(isLoading: true)) {
    init();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenPrefKey);
      final savedUserJson = prefs.getString(_userPrefKey);

      if (savedToken != null && savedToken.isNotEmpty) {
        _ref.read(authTokenProvider.notifier).state = savedToken;

        if (savedUserJson != null) {
          try {
            final userMap = jsonDecode(savedUserJson) as Map<String, dynamic>;
            final cachedUser = UserModel.fromJson(userMap);
            state = AuthState(user: cachedUser, token: savedToken);
          } catch (e) {
            debugPrint('[AUTH] Failed to parse cached user: $e');
          }
        }

        // Validate or refresh with backend /api/me
        await fetchCurrentUser();
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      debugPrint('[AUTH] Error initializing auth state: $e');
      state = const AuthState(isLoading: false);
    }
  }

  /// Authoritative GET /api/me call verifying token and fetching user record
  Future<bool> fetchCurrentUser() async {
    try {
      final client = _ref.read(apiClientProvider);
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.me);

      if (response.data != null) {
        final user = UserModel.fromJson(response.data!);
        final token = _ref.read(authTokenProvider);
        state = AuthState(user: user, token: token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userPrefKey, jsonEncode(user.toJson()));
        return true;
      }
    } catch (e) {
      debugPrint('[AUTH] fetchCurrentUser error: $e');
      if (state.user == null) {
        state = AuthState(error: e.toString());
      }
    }
    return false;
  }

  /// Logs in with a Firebase ID token or deterministic test token
  Future<bool> loginWithToken(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _ref.read(authTokenProvider.notifier).state = token;
      final client = _ref.read(apiClientProvider);
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.me);

      if (response.data != null) {
        final user = UserModel.fromJson(response.data!);
        state = AuthState(user: user, token: token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenPrefKey, token);
        await prefs.setString(_userPrefKey, jsonEncode(user.toJson()));
        return true;
      } else {
        state = const AuthState(error: 'Failed to retrieve user profile from backend.');
        return false;
      }
    } catch (e) {
      _ref.read(authTokenProvider.notifier).state = null;
      state = AuthState(error: e.toString());
      return false;
    }
  }

  /// Quick Login for Phone 1 (Provider / GreenLeaf Hotel)
  Future<bool> demoLoginProvider() async {
    const demoToken = 'test-firebase-sender-hotel-1:hotel@greenleaf.demo';
    return await loginWithToken(demoToken);
  }

  /// Quick Login for Phone 2 (Recipient / Hope Community Kitchen)
  Future<bool> demoLoginRecipient() async {
    const demoToken = 'test-firebase-recipient-kitchen-1:contact@hopekitchen.demo';
    return await loginWithToken(demoToken);
  }

  /// Login with email: maps seeded accounts or standard Firebase test tokens
  Future<bool> loginWithEmail(String email, {String? password}) async {
    final cleanEmail = email.trim().toLowerCase();

    // Map seeded accounts to their exact database firebase_uid
    String token;
    if (cleanEmail == 'hotel@greenleaf.demo') {
      token = 'test-firebase-sender-hotel-1:hotel@greenleaf.demo';
    } else if (cleanEmail == 'events@sunrisewedding.demo') {
      token = 'test-firebase-sender-wedding-1:events@sunrisewedding.demo';
    } else if (cleanEmail == 'mess@abccollege.demo') {
      token = 'test-firebase-sender-college-1:mess@abccollege.demo';
    } else if (cleanEmail == 'contact@hopekitchen.demo') {
      token = 'test-firebase-recipient-kitchen-1:contact@hopekitchen.demo';
    } else if (cleanEmail == 'help@sunriseshelter.demo') {
      token = 'test-firebase-recipient-shelter-1:help@sunriseshelter.demo';
    } else if (cleanEmail == 'admin@carebridge.demo') {
      token = 'test-firebase-recipient-center-1:admin@carebridge.demo';
    } else if (cleanEmail.contains(':') || cleanEmail.contains('.')) {
      final safeUid = cleanEmail.replaceAll('@', '-').replaceAll('.', '-');
      token = 'test-$safeUid:$cleanEmail';
    } else {
      token = 'test-$cleanEmail:$cleanEmail';
    }

    return await loginWithToken(token);
  }

  Future<bool> registerUser({
    required String email,
    required String organizationName,
    required String organizationType,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final safeId =
          organizationName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
      final generatedToken = 'test-$safeId:${email.trim()}';

      final success = await loginWithToken(generatedToken);
      if (!success) {
        final user = UserModel(
          id: 'usr-$safeId',
          firebaseUid: 'fb-$safeId',
          email: email.trim(),
          organizationName: organizationName.trim(),
          organizationType: organizationType.trim(),
          role: role,
          verificationStatus: 'verified',
        );
        _ref.read(authTokenProvider.notifier).state = generatedToken;
        state = AuthState(user: user, token: generatedToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenPrefKey, generatedToken);
        await prefs.setString(_userPrefKey, jsonEncode(user.toJson()));
        return true;
      }
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    _ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenPrefKey);
      await prefs.remove(_userPrefKey);
    } catch (e) {
      debugPrint('[AUTH] Error during logout: $e');
    }
  }
}

final authServiceProvider =
    StateNotifierProvider<AuthService, AuthState>((ref) {
  return AuthService(ref);
});
