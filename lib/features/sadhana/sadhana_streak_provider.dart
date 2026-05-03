import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sadhana_today_provider.dart';
import '../users/user_session_provider.dart';

String _todayIsoDate() {
  return DateTime.now().toIso8601String().split('T').first;
}

final sadhanaStreakProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(selectedUserProvider);

  if (user == null) return 0;

  final service = ref.read(sadhanaTodayServiceProvider);

  return service.getSadhanaStreak(user.id, entryDate: _todayIsoDate());
});
