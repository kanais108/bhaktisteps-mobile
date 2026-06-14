import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/events_service.dart';
import '../users/user_session_provider.dart';

class FriendlyEventsException implements Exception {
  final String message;

  const FriendlyEventsException(this.message);

  @override
  String toString() => message;
}

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

  try {
    return await service.getEvents().timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw const FriendlyEventsException(
          'Events are taking longer than expected. Please pull down to refresh.',
        );
      },
    );
  } on FriendlyEventsException {
    rethrow;
  } on DioException catch (error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 401) {
      throw const FriendlyEventsException('Please login again to view events.');
    }

    if (statusCode == 404) {
      throw const FriendlyEventsException('No events are available right now.');
    }

    if (statusCode != null && statusCode >= 500) {
      throw const FriendlyEventsException(
        'Events service is temporarily unavailable. Please try again later.',
      );
    }

    throw const FriendlyEventsException(
      'Could not load events. Please pull down to refresh.',
    );
  } catch (_) {
    throw const FriendlyEventsException(
      'Could not load events. Please pull down to refresh.',
    );
  }
});
