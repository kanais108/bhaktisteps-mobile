import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sadhana_today_provider.dart';
import '../users/user_session_provider.dart';

final sadhanaHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(selectedUserProvider);

  if (user == null) return [];

  final service = ref.read(sadhanaTodayServiceProvider);
  return service.getSadhanaHistory(user.id);
});
