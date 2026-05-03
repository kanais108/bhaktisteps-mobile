import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events/events_provider.dart';
import '../sadhana/sadhana_streak_provider.dart';
import '../sadhana/sadhana_today_provider.dart';
import '../users/user_session_provider.dart';

class DashboardData {
  final int upcomingEvents;
  final bool sadhanaDoneToday;
  final int streak;

  DashboardData({
    required this.upcomingEvents,
    required this.sadhanaDoneToday,
    required this.streak,
  });
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final events = await ref.watch(eventsProvider.future);
  final user = ref.watch(selectedUserProvider);

  if (user == null) {
    return DashboardData(upcomingEvents: 0, sadhanaDoneToday: false, streak: 0);
  }

  final isDone = await ref.watch(sadhanaTodayProvider.future);
  final streak = await ref.watch(sadhanaStreakProvider.future);

  return DashboardData(
    upcomingEvents: events.length,
    sadhanaDoneToday: isDone,
    streak: streak,
  );
});
