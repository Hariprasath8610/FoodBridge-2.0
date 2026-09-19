import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// Centralized HTTP & REST API Client for FoodBridge FastAPI Backend
class ApiClient {
  final Ref _ref;
  late final Dio _dio;

  ApiClient(this._ref) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Primary Interceptor: Auth injection, dynamic baseUrl, structured logging, error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final stopwatch = Stopwatch()..start();
          options.extra['stopwatch'] = stopwatch;

          // Dynamically attach the active configured base URL
          final config = _ref.read(serverConfigProvider);
          options.baseUrl = config.baseUrl;

          // Attach active Firebase ID token if present
          final token = _ref.read(authTokenProvider);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint(
              '[API REQUEST] ${options.method} ${options.baseUrl}${options.path}'
              '${options.queryParameters.isNotEmpty ? ' ?${options.queryParameters}' : ''}'
              '${token != null ? ' [Bearer Token Attached]' : ' [Unauthenticated]'}',
            );
            if (options.data != null) {
              debugPrint('[API REQUEST BODY] ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          final stopwatch = response.requestOptions.extra['stopwatch'] as Stopwatch?;
          final elapsedMs = stopwatch?.elapsedMilliseconds ?? 0;

          if (kDebugMode) {
            debugPrint(
              '[API RESPONSE] [${response.statusCode}] ${response.requestOptions.method} '
              '${response.requestOptions.path} (${elapsedMs}ms)',
            );
          }

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final stopwatch = e.requestOptions.extra['stopwatch'] as Stopwatch?;
          final elapsedMs = stopwatch?.elapsedMilliseconds ?? 0;

          String userFriendlyMessage;
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            userFriendlyMessage =
                'Connection timed out after 15s. Please check your network or server URL.';
          } else if (e.type == DioExceptionType.connectionError) {
            final config = _ref.read(serverConfigProvider);
            userFriendlyMessage =
                'Cannot reach server at ${config.baseUrl}. Make sure FoodBridge FastAPI is running.';
          } else if (e.response != null) {
            final status = e.response?.statusCode;
            final data = e.response?.data;

            if (status == 401) {
              userFriendlyMessage =
                  _extractFastApiDetail(data) ?? 'Authentication required or token expired.';
              // Trigger unauthorized handler: clear active token
              _ref.read(authTokenProvider.notifier).state = null;
            } else if (status == 403) {
              userFriendlyMessage =
                  _extractFastApiDetail(data) ?? 'Access forbidden for your organization role.';
            } else if (status == 404) {
              userFriendlyMessage =
                  _extractFastApiDetail(data) ?? 'Requested resource not found.';
            } else if (status == 422) {
              userFriendlyMessage = _formatValidationErrors(data);
            } else {
              userFriendlyMessage =
                  _extractFastApiDetail(data) ?? 'Server error ($status).';
            }
          } else {
            userFriendlyMessage = e.message ?? 'An unexpected network error occurred.';
          }

          if (kDebugMode) {
            debugPrint(
              '[API ERROR] [${e.response?.statusCode ?? 'NETWORK'}] ${e.requestOptions.method} '
              '${e.requestOptions.path} (${elapsedMs}ms) => $userFriendlyMessage',
            );
          }

          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: ApiException(
                message: userFriendlyMessage,
                statusCode: e.response?.statusCode,
                data: e.response?.data,
              ),
              type: e.type,
              response: e.response,
            ),
          );
        },
      ),
    );
  }

  static String? _extractFastApiDetail(dynamic data) {
    if (data is Map && data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) return _formatValidationErrors(data);
    }
    return null;
  }

  static String _formatValidationErrors(dynamic data) {
    if (data is Map && data.containsKey('detail') && data['detail'] is List) {
      final errorList = data['detail'] as List;
      final messages = errorList.map((err) {
        if (err is Map) {
          final loc = (err['loc'] as List?)?.last?.toString() ?? 'field';
          final msg = err['msg']?.toString() ?? 'invalid';
          return '$loc: $msg';
        }
        return err.toString();
      }).toList();
      return 'Validation error: ${messages.join(', ')}';
    }
    return 'Invalid data submitted. Please check your inputs.';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(
        message: e.message ?? 'Network GET request failed.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(
        message: e.message ?? 'Network POST request failed.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(
        message: e.message ?? 'Network PUT request failed.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

// Global Auth Token Provider
final authTokenProvider = StateProvider<String?>((ref) => null);

// ApiClient Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});
