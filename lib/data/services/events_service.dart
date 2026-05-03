import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/event_model.dart';
import 'api_service.dart';

class EventsService {
  final ApiService apiService;

  EventsService(this.apiService);

  Future<List<EventModel>> getEvents() async {
    debugPrint('EventsService.getEvents() called');

    final Response response = await apiService.dio.get('/events');

    debugPrint('EventsService.getEvents() raw data: ${response.data}');

    final List data = response.data as List;
    return data
        .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    final Response response = await apiService.dio.post('/events', data: data);

    return EventModel.fromJson(response.data as Map<String, dynamic>);
  }
}
