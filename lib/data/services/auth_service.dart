import 'package:dio/dio.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthResult {
  final String token;
  final UserModel user;

  AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthService {
  final ApiService apiService;

  AuthService(this.apiService);

  Future<void> requestOtp(String email) async {
    await apiService.dio.post(
      '/auth/request-otp',
      data: {'email': email.trim()},
    );
  }

  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final Response response = await apiService.dio.post(
      '/auth/verify-otp',
      data: {'email': email.trim(), 'otp': otp.trim()},
    );

    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }
}
