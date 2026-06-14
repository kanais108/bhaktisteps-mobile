import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<File> exportMySadhanaReport({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final from = _dateKey(fromDate);
    final to = _dateKey(toDate);

    final Response<List<int>> response = await apiService.dio.get<List<int>>(
      '/sadhana/report/export',
      queryParameters: {'userId': userId, 'fromDate': from, 'toDate': to},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    final bytes = response.data;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Empty report received');
    }

    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/bhakti-steps-sadhana-$from-to-$to.xlsx',
    );

    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  Future<void> exportAndOpenMySadhanaReport({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final file = await exportMySadhanaReport(
      userId: userId,
      fromDate: fromDate,
      toDate: toDate,
    );

    await OpenFilex.open(file.path);
  }

  Future<Map<String, dynamic>> emailMySadhanaReport({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
    required String email,
  }) async {
    final Response response = await apiService.dio.post(
      '/sadhana/report/email',
      data: {
        'userId': userId,
        'fromDate': _dateKey(fromDate),
        'toDate': _dateKey(toDate),
        'email': email.trim(),
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
