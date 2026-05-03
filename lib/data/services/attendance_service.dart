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
}
