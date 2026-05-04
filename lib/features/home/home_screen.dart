import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'dashboard_provider.dart';
import '../events/events_provider.dart';
import '../sadhana/sadhana_today_provider.dart';
import '../../navigation/app_router.dart';
import '../users/user_session_provider.dart';
import '../users/user_selector_screen.dart';
import '../web/in_app_webview_screen.dart';
import '../contact/contact_us_screen.dart';
import '../content/content_page_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFF59E0B);
  static const Color leaf = Color(0xFF16A34A);
  static const Color drawerPurple = Color(0xFF1E3A8A);

  static void showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title coming soon')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const _BhaktiDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Header(),
                      const SizedBox(height: 20),
                      const _DailyBlessingCard(),
                      const SizedBox(height: 16),
                      const _SadhanaStatusCard(),
                      const SizedBox(height: 18),
                      const _DashboardCards(),
                      const SizedBox(height: 32),
                      const _SectionTitleImpl(
                        title: 'Quick Actions',
                        subtitle: 'Everything you need for today',
                      ),
                      const SizedBox(height: 16),
                      const _QuickActionsGrid(),
                      const SizedBox(height: 28),
                      const _SectionTitleImpl(
                        title: 'Upcoming Events',
                        subtitle: 'Programs and gatherings ahead',
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              eventsAsync.when(
                data: (events) {
                  final now = DateTime.now();

                  final upcomingEvents =
                      events
                          .where((event) => event.isActive)
                          .where((event) => event.endsAt.toLocal().isAfter(now))
                          .toList()
                        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

                  if (upcomingEvents.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _EmptyEventsCard(),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: upcomingEvents.length > 5
                          ? 5
                          : upcomingEvents.length,
                      itemBuilder: (context, index) {
                        final event = upcomingEvents[index];

                        return _EventCard(
                          title: event.title,
                          category: _beautifyText(event.category),
                          location:
                              event.locationName ?? 'Location to be announced',
                          startTime: DateFormat(
                            'dd MMM yyyy • hh:mm a',
                          ).format(event.startsAt.toLocal()),
                          endTime: DateFormat(
                            'hh:mm a',
                          ).format(event.endsAt.toLocal()),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _LoadingEventsCard(),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ErrorEventsCard(error: error.toString()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _beautifyText(String value) {
    return value
        .split('_')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(selectedUserProvider);
    final firstName = (selectedUser?.fullName.trim().isNotEmpty ?? false)
        ? selectedUser!.fullName.trim().split(' ').first
        : 'Devotee';

    return Row(
      children: [
        Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HomeScreen.primary, HomeScreen.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: HomeScreen.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bhakti Steps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: HomeScreen.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hare Krishna, $firstName',
                style: const TextStyle(
                  fontSize: 13,
                  color: HomeScreen.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BhaktiDrawer extends ConsumerWidget {
  const _BhaktiDrawer();

  void _closeDrawer(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(selectedUserProvider);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [HomeScreen.primary, HomeScreen.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.temple_hindu_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bhakti Steps',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: HomeScreen.drawerPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Recognize • Revitalize • Progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: HomeScreen.textMuted,
                      ),
                    ),
                    if (selectedUser != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        selectedUser.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HomeScreen.textDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    _DrawerTile(
                      icon: Icons.home_rounded,
                      title: 'Home / Dashboard',
                      selected: true,
                      onTap: () {
                        _closeDrawer(context);
                        MainScreen.of(context)?.goToTab(AppTab.home);
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      onTap: () {
                        _closeDrawer(context);
                        MainScreen.of(context)?.goToTab(AppTab.profile);
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Certifications',
                      onTap: () {
                        _closeDrawer(context);
                        HomeScreen.showComingSoon(context, 'Certifications');
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.description_outlined,
                      title: 'My Documents',
                      onTap: () {
                        _closeDrawer(context);
                        HomeScreen.showComingSoon(context, 'My Documents');
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About Us',
                      onTap: () {
                        _closeDrawer(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContentPageScreen(
                              slug: 'about-us',
                              fallbackTitle: 'About Us',
                            ),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.call_outlined,
                      title: 'Contact Us',
                      onTap: () {
                        _closeDrawer(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.music_note_rounded,
                      title: 'Temple Songs & Prayers',
                      onTap: () {
                        _closeDrawer(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContentPageScreen(
                              slug: 'temple-songs-prayers',
                              fallbackTitle: 'Temple Songs & Prayers',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HomeScreen.drawerPurple,
                          side: BorderSide(
                            color: HomeScreen.drawerPurple.withValues(
                              alpha: 0.18,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(selectedUserProvider.notifier)
                              .logout();

                          if (!context.mounted) return;

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const UserSelectorScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? HomeScreen.drawerPurple.withValues(alpha: 0.10)
        : Colors.transparent;
    final fg = selected ? HomeScreen.drawerPurple : const Color(0xFF6C6C6C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyBlessingCard extends StatelessWidget {
  const _DailyBlessingCard();

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, dd MMMM').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0ECFF), Color(0xFFC7DBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HomeScreen.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: HomeScreen.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  today,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F6B95),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Begin your day with steadiness, seva, and remembrance.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HomeScreen.textDark,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SadhanaStatusCard extends ConsumerWidget {
  const _SadhanaStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sadhanaAsync = ref.watch(sadhanaTodayProvider);

    return GestureDetector(
      onTap: () {
        MainScreen.of(context)?.goToTab(AppTab.sadhana);
      },
      child: sadhanaAsync.when(
        data: (done) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: done
                    ? const [Color(0xFFE6F4EA), Color(0xFFCFF3D6)]
                    : const [Color(0xFFEFF6FF), Color(0xFFDCEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: (done ? HomeScreen.leaf : HomeScreen.accent)
                      .withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.self_improvement_rounded,
                    size: 28,
                    color: done ? HomeScreen.leaf : HomeScreen.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done ? 'Sadhana Completed' : 'Sadhana Pending',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: HomeScreen.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        done
                            ? 'Wonderful. Your sadhana has been submitted for today.'
                            : 'Take a few moments to complete and submit today’s sadhana.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: HomeScreen.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: HomeScreen.textMuted,
                  size: 20,
                ),
              ],
            ),
          );
        },
        loading: () => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 14),
              Text(
                'Checking today’s sadhana...',
                style: TextStyle(fontSize: 14, color: HomeScreen.textMuted),
              ),
            ],
          ),
        ),
        error: (error, _) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Text(
            'Could not load sadhana status.',
            style: TextStyle(fontSize: 14, color: HomeScreen.textMuted),
          ),
        ),
      ),
    );
  }
}

class _SectionTitleImpl extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitleImpl({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: HomeScreen.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: HomeScreen.textMuted),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid();

  bool _isLeaderRole(String? role) {
    return role == 'SUPER_ADMIN' ||
        role == 'CIRCLE_LEADER' ||
        role == 'SECTOR_LEADER' ||
        role == 'SERVANT_LEADER';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(selectedUserProvider);
    final isLeader = _isLeaderRole(selectedUser?.role);

    final actions = [
      _ActionConfig(
        icon: Icons.event_note_rounded,
        title: 'Events',
        subtitle: 'View temple programs',
        color: HomeScreen.primary,
        onTap: () => MainScreen.of(context)?.goToTab(AppTab.events),
      ),
      if (isLeader)
        _ActionConfig(
          icon: Icons.fact_check_rounded,
          title: 'Attendance',
          subtitle: 'Mark group attendance',
          color: HomeScreen.leaf,
          onTap: () => MainScreen.of(context)?.goToTab(AppTab.attendance),
        ),
      _ActionConfig(
        icon: Icons.self_improvement_rounded,
        title: 'Sadhana',
        subtitle: 'Submit daily practice',
        color: const Color(0xFF7C3AED),
        onTap: () => MainScreen.of(context)?.goToTab(AppTab.sadhana),
      ),
      _ActionConfig(
        icon: Icons.person_rounded,
        title: 'Profile',
        subtitle: 'View your details',
        color: HomeScreen.accent,
        onTap: () => MainScreen.of(context)?.goToTab(AppTab.profile),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: actions.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionItem(
          icon: action.icon,
          title: action.title,
          subtitle: action.subtitle,
          color: action.color,
          onTap: action.onTap,
        );
      },
    );
  }
}

class _ActionConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _ActionConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _ActionItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionItem> createState() => _ActionItemState();
}

class _ActionItemState extends State<_ActionItem> {
  bool isPressed = false;

  void handleTapDown(TapDownDetails _) {
    setState(() => isPressed = true);
  }

  void handleTapUp(TapUpDetails _) {
    setState(() => isPressed = false);
  }

  void handleTapCancel() {
    setState(() => isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          onTapDown: handleTapDown,
          onTapUp: handleTapUp,
          onTapCancel: handleTapCancel,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [widget.color.withValues(alpha: 0.14), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: widget.color.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 26),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.color.withValues(alpha: 0.75),
                        size: 20,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: HomeScreen.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: HomeScreen.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String category;
  final String location;
  final String startTime;
  final String endTime;

  const _EventCard({
    required this.title,
    required this.category,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: HomeScreen.cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: HomeScreen.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: HomeScreen.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HomeScreen.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: HomeScreen.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: HomeScreen.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HomeScreen.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: HomeScreen.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$startTime  •  $endTime',
                          style: const TextStyle(
                            fontSize: 13,
                            color: HomeScreen.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 42,
            color: HomeScreen.primaryDark,
          ),
          SizedBox(height: 12),
          Text(
            'No upcoming events yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: HomeScreen.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Once events are created, they will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: HomeScreen.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LoadingEventsCard extends StatelessWidget {
  const _LoadingEventsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: HomeScreen.primary),
      ),
    );
  }
}

class _DashboardCards extends ConsumerWidget {
  const _DashboardCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return dashboardAsync.when(
      loading: () => const _DashboardLoading(),
      error: (e, _) => _DashboardError(error: e.toString()),
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Snapshot',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: HomeScreen.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'A quick view of your practice and activity',
              style: TextStyle(fontSize: 13, color: HomeScreen.textMuted),
            ),
            const SizedBox(height: 16),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
              ),
              children: [
                _AnimatedDashboardItem(
                  child: _DashboardCard(
                    title: 'Sadhana Today',
                    value: data.sadhanaDoneToday ? 'Done' : 'Pending',
                    subtitle: data.sadhanaDoneToday
                        ? 'Completed for today'
                        : 'Still waiting today',
                    icon: Icons.self_improvement_rounded,
                    color: data.sadhanaDoneToday
                        ? HomeScreen.leaf
                        : HomeScreen.accent,
                  ),
                ),
                _AnimatedDashboardItem(
                  child: _DashboardCard(
                    title: 'Upcoming Events',
                    value: '${data.upcomingEvents}',
                    subtitle: data.upcomingEvents == 1
                        ? '1 program ahead'
                        : '${data.upcomingEvents} programs ahead',
                    icon: Icons.event_rounded,
                    color: HomeScreen.primary,
                  ),
                ),
                if (selectedUser?.isLeader == true)
                  const _AnimatedDashboardItem(
                    child: _DashboardCard(
                      title: 'Attendance',
                      value: 'Track',
                      subtitle: 'Record attendance',
                      icon: Icons.fact_check_rounded,
                      color: HomeScreen.drawerPurple,
                    ),
                  )
                else
                  const _AnimatedDashboardItem(
                    child: _DashboardCard(
                      title: 'Profile',
                      value: 'View',
                      subtitle: 'See your details',
                      icon: Icons.person_rounded,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                _AnimatedDashboardItem(
                  child: _AnimatedStreakCard(streak: data.streak),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InsightCard(
              streak: data.streak,
              upcomingEvents: data.upcomingEvents,
              sadhanaDoneToday: data.sadhanaDoneToday,
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedDashboardItem extends StatelessWidget {
  final Widget child;

  const _AnimatedDashboardItem({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 400),
        child: child,
      ),
    );
  }
}

class _AnimatedStreakCard extends StatefulWidget {
  final int streak;

  const _AnimatedStreakCard({required this.streak});

  @override
  State<_AnimatedStreakCard> createState() => _AnimatedStreakCardState();
}

class _AnimatedStreakCardState extends State<_AnimatedStreakCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;
  late Animation<double> rotation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    rotation = Tween<double>(
      begin: -0.02,
      end: 0.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation.value,
          child: Transform.scale(scale: scale.value, child: child),
        );
      },
      child: _DashboardCard(
        title: 'Streak',
        value: '${widget.streak}',
        subtitle: widget.streak == 1 ? 'day in a row' : 'days in a row',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.14), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: HomeScreen.textDark,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HomeScreen.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: HomeScreen.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 14),
          Text(
            'Loading dashboard...',
            style: TextStyle(fontSize: 14, color: HomeScreen.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String error;

  const _DashboardError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Could not load dashboard right now.',
        style: TextStyle(color: HomeScreen.textMuted, fontSize: 14),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final int streak;
  final int upcomingEvents;
  final bool sadhanaDoneToday;

  const _InsightCard({
    required this.streak,
    required this.upcomingEvents,
    required this.sadhanaDoneToday,
  });

  @override
  Widget build(BuildContext context) {
    final bars = [
      streak > 0 ? 0.85 : 0.22,
      upcomingEvents > 0 ? 0.70 : 0.18,
      sadhanaDoneToday ? 0.95 : 0.35,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Snapshot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HomeScreen.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sadhanaDoneToday
                      ? 'You are on track today. Keep the momentum flowing.'
                      : 'A small effort today can strengthen your weekly flow.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: HomeScreen.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 82,
            height: 78,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniChartBar(
                  heightFactor: bars[0],
                  color: const Color(0xFFEF4444),
                  label: 'St',
                ),
                _MiniChartBar(
                  heightFactor: bars[1],
                  color: HomeScreen.primary,
                  label: 'Ev',
                ),
                _MiniChartBar(
                  heightFactor: bars[2],
                  color: HomeScreen.leaf,
                  label: 'Sd',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartBar extends StatelessWidget {
  final double heightFactor;
  final Color color;
  final String label;

  const _MiniChartBar({
    required this.heightFactor,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final safeFactor = heightFactor.clamp(0.12, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          width: 16,
          height: 54 * safeFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: HomeScreen.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ErrorEventsCard extends StatelessWidget {
  final String error;

  const _ErrorEventsCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        'Could not load events.\n$error',
        style: const TextStyle(color: HomeScreen.textMuted),
      ),
    );
  }
}
