import 'package:dio/dio.dart';

import 'api_service.dart';

class ContentPageService {
  final ApiService apiService;

  ContentPageService(this.apiService);

  Future<Map<String, dynamic>> getContentPage(String slug) async {
    final Response response = await apiService.dio.get('/content-pages/$slug');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
