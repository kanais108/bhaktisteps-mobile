import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio dio;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://bhaktistepsbackend-production.up.railway.app',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          debugPrint('API REQUEST -> ${options.method} ${options.uri}');
          debugPrint(
            'API TOKEN PRESENT -> ${token != null && token.isNotEmpty}',
          );

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint(
            'API RESPONSE <- ${response.requestOptions.method} ${response.requestOptions.uri} [${response.statusCode}]',
          );
          handler.next(response);
        },

        onError: (error, handler) {
          debugPrint(
            'API ERROR <- ${error.requestOptions.method} ${error.requestOptions.uri} '
            '[${error.response?.statusCode}] ${error.message}',
          );

          // 🔥 Convert technical errors → user-friendly messages
          String message = _mapErrorToMessage(error);

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: message,
            ),
          );
        },
      ),
    );
  }

  // 🔥 Centralized error mapping
  String _mapErrorToMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Requested data not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
