import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/attendance/attendance_screen.dart';
import '../features/events/events_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/sadhana/sadhana_screen.dart';
import '../features/users/user_selector_screen.dart';
import '../features/users/user_session_provider.dart';
import '../core/notifications/notification_service.dart';
import '../data/services/api_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SessionGate()),
    ],
  );
});

enum AppTab { home, events, attendance, sadhana, profile }

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(selectedUserProvider);

    if (selectedUser == null) {
      return const UserSelectorScreen();
    }

    return MainScreen(user: selectedUser);
  }
}

class MainScreen extends StatefulWidget {
  final AppUser user;
  final AppTab initialTab;

  const MainScreen({
    super.key,
    required this.user,
    this.initialTab = AppTab.home,
  });

  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color navBg = Colors.white;

  int index = 0;

  @override
  void initState() {
    super.initState();

    final targetIndex = visibleTabs.indexOf(widget.initialTab);
    index = targetIndex == -1 ? 0 : targetIndex;

    final notificationService = NotificationService(ApiService());

    notificationService.listenToNotifications(context);
    notificationService.handleNotificationTap(user: widget.user);
    notificationService.handleInitialNotification(user: widget.user);
  }

  List<AppTab> get visibleTabs {
    final role = widget.user.role;

    final isLeader =
        role == 'SUPER_ADMIN' ||
        role == 'CIRCLE_LEADER' ||
        role == 'SECTOR_LEADER' ||
        role == 'SERVANT_LEADER';

    if (isLeader) {
      return const [
        AppTab.home,
        AppTab.events,
        AppTab.attendance,
        AppTab.sadhana,
        AppTab.profile,
      ];
    }

    return const [AppTab.home, AppTab.events, AppTab.sadhana, AppTab.profile];
  }

  void changeTab(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }

  void goToTab(AppTab tab) {
    final targetIndex = visibleTabs.indexOf(tab);
    if (targetIndex != -1) {
      setState(() {
        index = targetIndex;
      });
    }
  }

  IconData _iconForTab(AppTab tab, bool selected) {
    switch (tab) {
      case AppTab.home:
        return selected ? Icons.home_rounded : Icons.home_outlined;
      case AppTab.events:
        return selected ? Icons.event_rounded : Icons.event_outlined;
      case AppTab.attendance:
        return selected ? Icons.fact_check_rounded : Icons.fact_check_outlined;
      case AppTab.sadhana:
        return selected
            ? Icons.self_improvement_rounded
            : Icons.self_improvement_outlined;
      case AppTab.profile:
        return selected ? Icons.person_rounded : Icons.person_outline_rounded;
    }
  }

  String _labelForTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return 'Home';
      case AppTab.events:
        return 'Events';
      case AppTab.attendance:
        return 'Attendance';
      case AppTab.sadhana:
        return 'Sadhana';
      case AppTab.profile:
        return 'Profile';
    }
  }

  Widget _screenForTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const HomeScreen();
      case AppTab.events:
        return const EventsScreen();
      case AppTab.attendance:
        return const AttendanceScreen();
      case AppTab.sadhana:
        return const SadhanaScreen();
      case AppTab.profile:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = visibleTabs;

    if (index >= tabs.length) {
      index = 0;
    }

    return Scaffold(
      body: _screenForTab(tabs[index]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Container(
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: List.generate(tabs.length, (tabIndex) {
                final tab = tabs[tabIndex];
                final selected = index == tabIndex;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => changeTab(tabIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: [primary, primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: selected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconForTab(tab, selected),
                            color: selected ? Colors.white : textMuted,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _labelForTab(tab),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? Colors.white : textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
