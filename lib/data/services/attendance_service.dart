import 'package:dio/dio.dart';
import 'api_service.dart';

class AttendanceService {
  final ApiService apiService;

  AttendanceService(this.apiService);

  Future<List<dynamic>> getAttendance({required String viewerUserId}) async {
    final Response response = await apiService.dio.get(
      '/attendance',
      queryParameters: {'viewerUserId': viewerUserId},
    );

    return response.data as List<dynamic>;
  }

  Future<void> createAttendance(Map<String, dynamic> data) async {
    await apiService.dio.post('/attendance', data: data);
  }

  Future<void> bulkCreateOrUpdateAttendance(Map<String, dynamic> data) async {
    await apiService.dio.post('/attendance/bulk', data: data);
  }

  Future<List<dynamic>> getProgramBatches() async {
    final Response response = await apiService.dio.get(
      '/program-attendance/batches',
    );

    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getProgramBatchMembers(String batchId) async {
    final Response response = await apiService.dio.get(
      '/program-attendance/batches/$batchId/members',
    );

    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getProgramBatchSessions(String batchId) async {
    final Response response = await apiService.dio.get(
      '/program-attendance/batches/$batchId/sessions',
    );

    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createProgramSession({
    required String batchId,
    required int weekNumber,
    required DateTime sessionDate,
    String? title,
    String? notes,
  }) async {
    final Response response = await apiService.dio.post(
      '/program-attendance/sessions',
      data: {
        'batchId': batchId,
        'weekNumber': weekNumber,
        'sessionDate': _dateKey(sessionDate),
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getProgramSessionAttendance(String sessionId) async {
    final Response response = await apiService.dio.get(
      '/program-attendance/sessions/$sessionId/attendance',
    );

    return response.data as List<dynamic>;
  }

  Future<void> bulkCreateOrUpdateProgramAttendance({
    required String sessionId,
    required List<Map<String, dynamic>> records,
  }) async {
    await apiService.dio.post(
      '/program-attendance/bulk',
      data: {'sessionId': sessionId, 'records': records},
    );
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
