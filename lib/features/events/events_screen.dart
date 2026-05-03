import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'event_detail_screen.dart';
import 'events_provider.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFF59E0B);
  static const Color green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(eventsProvider.future),
        child: eventsAsync.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(error: error.toString()),
          data: (events) {
            final now = DateTime.now();

            final upcomingEvents =
                events
                    .where((event) => event.isActive)
                    .where((event) => event.endsAt.toLocal().isAfter(now))
                    .toList()
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverAppBar(
                  expandedHeight: 170,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Events',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    background: _HeaderBackground(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: _WelcomeCard(count: upcomingEvents.length),
                  ),
                ),

                if (upcomingEvents.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: upcomingEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final event = upcomingEvents[index];
                        return _EventCard(
                          eventId: event.id,
                          title: event.title,
                          category: _beautifyText(event.category),
                          eventMode: _beautifyText(event.eventMode),
                          attendanceMode: _beautifyText(event.attendanceMode),
                          locationName: event.locationName,
                          posterImageUrl: event.posterImageUrl,
                          startsAt: event.startsAt.toLocal(),
                          endsAt: event.endsAt.toLocal(),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
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

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [EventsScreen.primary, EventsScreen.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          right: -28,
          top: 38,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 130,
            color: Colors.white.withValues(alpha: 0.13),
          ),
        ),
        Positioned(
          left: 22,
          bottom: 62,
          child: Row(
            children: [
              Icon(
                Icons.temple_hindu_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'Discover upcoming seva & sanga',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final int count;

  const _WelcomeCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: EventsScreen.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1 ? '1 upcoming event' : '$count upcoming events',
                  style: const TextStyle(
                    color: EventsScreen.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pull down to refresh the latest programs.',
                  style: TextStyle(
                    color: EventsScreen.textMuted,
                    fontSize: 13,
                    height: 1.35,
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

class _EventCard extends StatelessWidget {
  final String eventId;
  final String title;
  final String category;
  final String eventMode;
  final String attendanceMode;
  final String? locationName;
  final String? posterImageUrl;
  final DateTime startsAt;
  final DateTime endsAt;

  const _EventCard({
    required this.eventId,
    required this.title,
    required this.category,
    required this.eventMode,
    required this.attendanceMode,
    required this.locationName,
    required this.posterImageUrl,
    required this.startsAt,
    required this.endsAt,
  });

  @override
  Widget build(BuildContext context) {
    final posterUrl = posterImageUrl?.trim();
    final hasPoster = posterUrl != null && posterUrl.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: eventId),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPoster)
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: EventsScreen.primarySoft,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const _PosterFallback(),
                    ),
                  )
                else
                  const _PosterFallback(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DateBadge(date: startsAt),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: EventsScreen.textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _Pill(
                                      label: category,
                                      bg: EventsScreen.primarySoft,
                                      fg: EventsScreen.primary,
                                    ),
                                    _Pill(
                                      label: eventMode,
                                      bg: const Color(0xFFFFF7ED),
                                      fg: EventsScreen.accent,
                                    ),
                                    _Pill(
                                      label: attendanceMode,
                                      bg: const Color(0xFFF0FDF4),
                                      fg: EventsScreen.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoLine(
                        icon: Icons.schedule_rounded,
                        text:
                            '${DateFormat('hh:mm a').format(startsAt)} - ${DateFormat('hh:mm a').format(endsAt)}',
                      ),
                      if (locationName != null &&
                          locationName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoLine(
                          icon: Icons.location_on_rounded,
                          text: locationName!,
                        ),
                      ],
                    ],
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

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.event_available_rounded,
          color: EventsScreen.primary,
          size: 44,
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: EventsScreen.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('dd').format(date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: EventsScreen.textMuted, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: EventsScreen.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 58,
                color: EventsScreen.textMuted,
              ),
              SizedBox(height: 14),
              Text(
                'No upcoming events',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: EventsScreen.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Future temple programs will appear here once they are created.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EventsScreen.textMuted, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            'Could not load events.\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: EventsScreen.textMuted, height: 1.4),
          ),
        ),
      ),
    );
  }
}
