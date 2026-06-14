import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/users/user_session_provider.dart';

class ApiService {
  late final Dio dio;

  final Future<void> Function()? onUnauthorized;
  bool _handlingUnauthorized = false;

  ApiService({this.onUnauthorized}) {
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

        onError: (error, handler) async {
          debugPrint(
            'API ERROR <- ${error.requestOptions.method} ${error.requestOptions.uri} '
            '[${error.response?.statusCode}] ${error.message}',
          );

          if (error.response?.statusCode == 401) {
            await _handleUnauthorized();
          }

          final message = _mapErrorToMessage(error);

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

  Future<void> _handleUnauthorized() async {
    if (_handlingUnauthorized) return;

    _handlingUnauthorized = true;

    try {
      if (onUnauthorized != null) {
        await onUnauthorized!();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_full_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_role');
      await prefs.remove('auth_token');
    } finally {
      _handlingUnauthorized = false;
    }
  }

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
  return ApiService(
    onUnauthorized: () async {
      await ref.read(selectedUserProvider.notifier).logout();
    },
  );
});
