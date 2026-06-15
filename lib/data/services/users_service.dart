import 'package:dio/dio.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class UsersService {
  final ApiService apiService;

  UsersService(this.apiService);

  Future<UserModel?> findUserByEmail(String email) async {
    final Response response = await apiService.dio.get(
      '/users/by-email',
      queryParameters: {'email': email},
    );

    if (response.data == null) return null;
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> createUser({
    required String fullName,
    required String email,
  }) async {
    final Response response = await apiService.dio.post(
      '/users/register',
      data: {'fullName': fullName, 'email': email.trim()},
    );

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserModel>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await apiService.dio.get(
      '/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
        if (isActive != null) 'isActive': isActive.toString(),
      },
    );

    final responseData = response.data;

    if (responseData is List) {
      return responseData
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    if (responseData is Map && responseData['data'] is List) {
      final List data = responseData['data'] as List;

      return data
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return [];
  }
}
