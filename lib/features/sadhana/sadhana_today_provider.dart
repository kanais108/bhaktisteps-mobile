import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_service.dart';
import '../../data/services/sadhana_service.dart';
import '../users/user_session_provider.dart';

final sadhanaTodayServiceProvider = Provider<SadhanaService>((ref) {
  final api = ref.read(apiServiceProvider);
  return SadhanaService(api);
});

final sadhanaTodayProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(selectedUserProvider);

  if (user == null) {
    return false;
  }

  final service = ref.read(sadhanaTodayServiceProvider);
  return service.isSadhanaDoneToday(user.id);
});
