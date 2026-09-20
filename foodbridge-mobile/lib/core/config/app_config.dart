import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  final String baseUrl;
  final bool isCustom;

  const ServerConfig({
    required this.baseUrl,
    this.isCustom = false,
  });

  ServerConfig copyWith({String? baseUrl, bool? isCustom}) {
    return ServerConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

class ServerConfigNotifier extends StateNotifier<ServerConfig> {
  static const String _prefKey = 'foodbridge_server_base_url';

  /// Configurable at build-time via `--dart-define=API_BASE_URL=http://<IP>:8000`
  /// Defaults to the active host Wi-Fi LAN IP (10.56.58.44:8000) for real Android device access
  static const String configuredApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.56.58.44:8000',
  );

  static const String defaultBaseUrl = configuredApiUrl;

  ServerConfigNotifier() : super(const ServerConfig(baseUrl: defaultBaseUrl)) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        state = ServerConfig(baseUrl: savedUrl, isCustom: true);
      }
    } catch (_) {}
  }

  Future<void> updateBaseUrl(String newUrl) async {
    String normalized = newUrl.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    state = ServerConfig(baseUrl: normalized, isCustom: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, normalized);
    } catch (_) {}
  }

  Future<void> resetToDefault() async {
    state = const ServerConfig(baseUrl: defaultBaseUrl, isCustom: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }
}

final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, ServerConfig>((ref) {
  return ServerConfigNotifier();
});
