import 'package:dio/dio.dart';
import '../models/group_member_model.dart';
import 'api_service.dart';

class GroupMembersService {
  final ApiService apiService;

  GroupMembersService(this.apiService);

  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    final Response response = await apiService.dio.get(
      '/group-members',
      queryParameters: {'groupId': groupId},
    );

    final List data = response.data;

    return data.map((e) => GroupMemberModel.fromJson(e)).toList();
  }
}
