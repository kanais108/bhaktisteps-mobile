import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_service.dart';
import '../../data/services/attendance_service.dart';
import '../users/user_session_provider.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final api = ref.read(apiServiceProvider);
  return AttendanceService(api);
});

final attendanceProvider = FutureProvider<List<dynamic>>((ref) async {
  final selectedUser = ref.watch(selectedUserProvider);

  if (selectedUser == null) {
    return [];
  }

  final service = ref.read(attendanceServiceProvider);
  return service.getAttendance(viewerUserId: selectedUser.id);
});
