import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_service.dart';
import '../../data/services/sadhana_service.dart';
import '../users/user_session_provider.dart';

final sadhanaTodayServiceProvider = Provider<SadhanaService>((ref) {
  final api = ref.read(apiServiceProvider);
  return SadhanaService(api);
});

String _todayIsoDate() {
  return DateTime.now().toIso8601String().split('T').first;
}

final sadhanaTodayEntryProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final user = ref.watch(selectedUserProvider);

  if (user == null) {
    return null;
  }

  final service = ref.read(sadhanaTodayServiceProvider);

  return service.getTodaySadhanaEntry(user.id, entryDate: _todayIsoDate());
});

final sadhanaTodayProvider = FutureProvider<bool>((ref) async {
  final entry = await ref.watch(sadhanaTodayEntryProvider.future);
  return entry != null;
});
