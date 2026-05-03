import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_service.dart';
import '../../data/services/attendance_service.dart';
import '../../data/services/groups_service.dart';
import '../../data/services/group_members_service.dart';
import '../users/user_session_provider.dart';

final bulkAttendanceServiceProvider = Provider<AttendanceService>((ref) {
  final api = ref.read(apiServiceProvider);
  return AttendanceService(api);
});

final groupsServiceProvider = Provider<GroupsService>((ref) {
  final api = ref.read(apiServiceProvider);
  return GroupsService(api);
});

final groupMembersServiceProvider = Provider<GroupMembersService>((ref) {
  final api = ref.read(apiServiceProvider);
  return GroupMembersService(api);
});

final scopedGroupsProvider = FutureProvider<List<dynamic>>((ref) async {
  final selectedUser = ref.watch(selectedUserProvider);

  if (selectedUser == null) {
    return [];
  }

  final service = ref.read(groupsServiceProvider);
  return service.getGroups();
});

final groupMembersProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  groupId,
) async {
  if (groupId.isEmpty) {
    return [];
  }

  final service = ref.read(groupMembersServiceProvider);
  return service.getMembers(groupId);
});
