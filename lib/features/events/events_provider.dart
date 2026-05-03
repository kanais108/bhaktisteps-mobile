import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/events_service.dart';
import '../users/user_session_provider.dart';

final eventsServiceProvider = Provider<EventsService>((ref) {
  final api = ref.read(apiServiceProvider);
  return EventsService(api);
});

final eventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final selectedUser = ref.watch(selectedUserProvider);

  debugPrint('eventsProvider -> selectedUser: ${selectedUser?.id}');
  debugPrint(
    'eventsProvider -> selectedUser token present: ${selectedUser?.token != null && selectedUser!.token!.isNotEmpty}',
  );

  if (selectedUser == null) {
    return [];
  }

  final service = ref.read(eventsServiceProvider);
  return service.getEvents().timeout(
    const Duration(seconds: 12),
    onTimeout: () {
      throw Exception('Events request timed out');
    },
  );
});
