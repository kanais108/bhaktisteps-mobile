import 'package:dio/dio.dart';
import 'api_service.dart';

class SadhanaService {
  final ApiService apiService;

  SadhanaService(this.apiService);

  Future<Map<String, dynamic>> createSadhana(Map<String, dynamic> data) async {
    final Response response = await apiService.dio.post('/sadhana', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateSadhana(
    String id,
    Map<String, dynamic> data,
  ) async {
    final Response response = await apiService.dio.patch(
      '/sadhana/$id',
      data: data,
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getSadhana() async {
    final Response response = await apiService.dio.get('/sadhana');
    return response.data as List<dynamic>;
  }

  Future<bool> isSadhanaDoneToday(String userId, {String? entryDate}) async {
    final Response response = await apiService.dio.get(
      '/sadhana/today',
      queryParameters: {
        'userId': userId,
        if (entryDate != null) 'entryDate': entryDate,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return data['done'] == true;
  }

  Future<Map<String, dynamic>?> getTodaySadhanaEntry(
    String userId, {
    String? entryDate,
  }) async {
    final Response response = await apiService.dio.get(
      '/sadhana/today-entry',
      queryParameters: {
        'userId': userId,
        if (entryDate != null) 'entryDate': entryDate,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final entry = data['entry'];

    if (entry == null) return null;

    return Map<String, dynamic>.from(entry as Map);
  }

  Future<int> getSadhanaStreak(String userId, {String? entryDate}) async {
    final Response response = await apiService.dio.get(
      '/sadhana/streak',
      queryParameters: {
        'userId': userId,
        if (entryDate != null) 'entryDate': entryDate,
      },
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
