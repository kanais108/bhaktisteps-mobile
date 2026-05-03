import 'package:dio/dio.dart';
import '../models/group_model.dart';
import 'api_service.dart';

class GroupsService {
  final ApiService apiService;

  GroupsService(this.apiService);

  Future<List<GroupModel>> getGroups() async {
    final Response response = await apiService.dio.get('/groups');

    final List data = response.data;

    return data.map((e) => GroupModel.fromJson(e)).toList();
  }
}
