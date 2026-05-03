import 'package:dio/dio.dart';
import 'api_service.dart';

class SadhanaService {
  final ApiService apiService;

  SadhanaService(this.apiService);

  Future<void> createSadhana(Map<String, dynamic> data) async {
    await apiService.dio.post('/sadhana', data: data);
  }

  Future<List<dynamic>> getSadhana() async {
    final Response response = await apiService.dio.get('/sadhana');
    return response.data as List<dynamic>;
  }

  Future<bool> isSadhanaDoneToday(String userId) async {
    final Response response = await apiService.dio.get(
      '/sadhana/today',
      queryParameters: {'userId': userId},
    );

    final data = response.data as Map<String, dynamic>;
    return data['done'] == true;
  }

  Future<int> getSadhanaStreak(String userId) async {
    final Response response = await apiService.dio.get(
      '/sadhana/streak',
      queryParameters: {'userId': userId},
    );

    final data = response.data as Map<String, dynamic>;
    return (data['streak'] as num?)?.toInt() ?? 0;
  }

  Future<List<dynamic>> getSadhanaHistory(String userId) async {
    final Response response = await apiService.dio.get(
      '/sadhana/history',
      queryParameters: {'userId': userId},
    );

    return response.data as List<dynamic>;
  }
}
