import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/services/api_service.dart';
import '../../main.dart';
import '../../navigation/app_router.dart';
import '../../features/users/user_session_provider.dart';
import '../../features/events/event_detail_screen.dart';

class NotificationService {
  final ApiService apiService;

  NotificationService(this.apiService);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initializeAndRegisterToken() async {
    try {
      if (kIsWeb) return;

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        String? apnsToken;

        for (int i = 0; i < 10; i++) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null && apnsToken.isNotEmpty) {
            debugPrint('APNS TOKEN PRESENT -> true');
            break;
          }
          await Future.delayed(const Duration(seconds: 1));
        }

        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint('APNS TOKEN -> empty after retries');
          return;
        }
      }

      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM TOKEN -> empty');
        return;
      }

      debugPrint('FCM TOKEN PRESENT -> true');

      await apiService.dio.post(
        '/device-tokens',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );

      debugPrint('FCM TOKEN REGISTERED -> true');

      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          if (newToken.isEmpty) return;

          await apiService.dio.post(
            '/device-tokens',
            data: {
              'token': newToken,
              'platform': Platform.isIOS ? 'ios' : 'android',
            },
          );

          debugPrint('FCM TOKEN REFRESH REGISTERED -> true');
        } catch (e) {
          debugPrint('FCM token refresh registration failed: $e');
        }
      });
    } catch (e) {
      debugPrint('Notification registration failed: $e');
    }
  }

  void listenToNotifications(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      debugPrint('PUSH RECEIVED foreground -> $title');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void handleNotificationTap({required AppUser user}) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('PUSH TAP background');
      _handleNavigation(message, user);
    });
  }

  Future<void> handleInitialNotification({required AppUser user}) async {
    final message = await _messaging.getInitialMessage();

    if (message != null) {
      debugPrint('PUSH TAP terminated');
      _handleNavigation(message, user);
    }
  }

  void _handleNavigation(RemoteMessage message, AppUser user) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final type = message.data['type']?.toString();
    final eventId = message.data['eventId']?.toString();

    debugPrint('Notification type -> $type');
    debugPrint('Event ID -> $eventId');

    if (type == 'events' && eventId != null && eventId.isNotEmpty) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainScreen(user: user, initialTab: AppTab.events),
        ),
        (route) => false,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = appNavigatorKey.currentState;
        if (nav == null) return;

        nav.push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: eventId),
          ),
        );
      });

      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainScreen(user: user, initialTab: _tabFromType(type)),
      ),
      (route) => false,
    );
  }

  AppTab _tabFromType(String? type) {
    switch (type) {
      case 'attendance':
        return AppTab.attendance;
      case 'sadhana':
        return AppTab.sadhana;
      case 'events':
        return AppTab.events;
      case 'profile':
        return AppTab.profile;
      case 'dashboard':
      default:
        return AppTab.home;
    }
  }
}
