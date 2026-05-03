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
      '/users',
      data: {'fullName': fullName, 'email': email.trim()},
    );

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserModel>> getUsers() async {
    final response = await apiService.dio.get('/users');
    final List data = response.data;

    return data.map((e) => UserModel.fromJson(e)).toList();
  }
}
