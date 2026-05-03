import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'sadhana_history_provider.dart';

class SadhanaHistoryScreen extends ConsumerWidget {
  const SadhanaHistoryScreen({super.key});

  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFF59E0B);
  static const Color green = Color(0xFF16A34A);
  static const Color teal = Color(0xFF0F766E);
  static const Color purple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  String _formatDate(String value) {
    final parsed = _parseDate(value);
    if (parsed == null) return value.split('T').first;
    return DateFormat('EEE, dd MMM yyyy').format(parsed);
  }

  String _shortDate(String value) {
    final parsed = _parseDate(value);
    if (parsed == null) return '--';
    return DateFormat('dd').format(parsed);
  }

  String _shortMonth(String value) {
    final parsed = _parseDate(value);
    if (parsed == null) return 'DAY';
    return DateFormat('MMM').format(parsed).toUpperCase();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _asBool(dynamic value) => value == true;

  int _practiceCount(Map<String, dynamic> item) {
    int count = 0;
    if (_asBool(item['mangalaArati'])) count++;
    if (_asBool(item['tulasiPuja'])) count++;
    if (_asBool(item['guruPuja'])) count++;
    if (_asBool(item['bhagavatamClass'])) count++;
    return count;
  }

  int _totalJapa(List<Map<String, dynamic>> items) {
    return items.fold<int>(0, (sum, item) => sum + _asInt(item['japaRounds']));
  }

  int _totalReading(List<Map<String, dynamic>> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + _asInt(item['readingMinutes']),
    );
  }

  int _totalService(List<Map<String, dynamic>> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + _asInt(item['serviceMinutes']),
    );
  }

  int _perfectDays(List<Map<String, dynamic>> items) {
    return items.where((item) => _practiceCount(item) == 4).length;
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(sadhanaHistoryProvider);

    try {
      await ref.read(sadhanaHistoryProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sadhanaHistoryProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Sadhana History'),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: historyAsync.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(error: error.toString()),
          data: (items) {
            final history = items
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

            history.sort((a, b) {
              final aDate = _parseDate((a['entryDate'] ?? '').toString());
              final bDate = _parseDate((b['entryDate'] ?? '').toString());

              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;

              return bDate.compareTo(aDate);
            });

            if (history.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: 620, child: _EmptyState()),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
              itemCount: history.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 18 : 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _HistorySummaryCard(
                    totalEntries: history.length,
                    totalJapa: _totalJapa(history),
                    totalReading: _totalReading(history),
                    totalService: _totalService(history),
                    perfectDays: _perfectDays(history),
                  );
                }

                final item = history[index - 1];

                final entryDate = (item['entryDate'] ?? '').toString();
                final japaRounds = _asInt(item['japaRounds']);
                final readingMinutes = _asInt(item['readingMinutes']);
                final serviceMinutes = _asInt(item['serviceMinutes']);
                final mangalaArati = _asBool(item['mangalaArati']);
                final tulasiPuja = _asBool(item['tulasiPuja']);
                final guruPuja = _asBool(item['guruPuja']);
                final bhagavatamClass = _asBool(item['bhagavatamClass']);
                final notes = (item['notes'] ?? '').toString().trim();

                return _HistoryCard(
                  day: _shortDate(entryDate),
                  month: _shortMonth(entryDate),
                  formattedDate: _formatDate(entryDate),
                  japaRounds: japaRounds,
                  readingMinutes: readingMinutes,
                  serviceMinutes: serviceMinutes,
                  mangalaArati: mangalaArati,
                  tulasiPuja: tulasiPuja,
                  guruPuja: guruPuja,
                  bhagavatamClass: bhagavatamClass,
                  notes: notes,
                  practiceCount: _practiceCount(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final int totalEntries;
  final int totalJapa;
  final int totalReading;
  final int totalService;
  final int perfectDays;

  const _HistorySummaryCard({
    required this.totalEntries,
    required this.totalJapa,
    required this.totalReading,
    required this.totalService,
    required this.perfectDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SadhanaHistoryScreen.primary, SadhanaHistoryScreen.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: SadhanaHistoryScreen.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your devotional journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Every entry is a small offering made with sincerity.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Entries',
                  value: '$totalEntries',
                  icon: Icons.calendar_month_rounded,
                  color: SadhanaHistoryScreen.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryStat(
                  label: 'Japa',
                  value: '$totalJapa',
                  icon: Icons.spa_rounded,
                  color: SadhanaHistoryScreen.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Reading',
                  value: '${totalReading}m',
                  icon: Icons.menu_book_rounded,
                  color: SadhanaHistoryScreen.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryStat(
                  label: 'Service',
                  value: '${totalService}m',
                  icon: Icons.volunteer_activism_rounded,
                  color: SadhanaHistoryScreen.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PerfectDaysPill(perfectDays: perfectDays),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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

class _PerfectDaysPill extends StatelessWidget {
  final int perfectDays;

  const _PerfectDaysPill({required this.perfectDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              perfectDays == 1
                  ? '1 day with all 4 practices completed'
                  : '$perfectDays days with all 4 practices completed',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String day;
  final String month;
  final String formattedDate;
  final int japaRounds;
  final int readingMinutes;
  final int serviceMinutes;
  final bool mangalaArati;
  final bool tulasiPuja;
  final bool guruPuja;
  final bool bhagavatamClass;
  final String notes;
  final int practiceCount;

  const _HistoryCard({
    required this.day,
    required this.month,
    required this.formattedDate,
    required this.japaRounds,
    required this.readingMinutes,
    required this.serviceMinutes,
    required this.mangalaArati,
    required this.tulasiPuja,
    required this.guruPuja,
    required this.bhagavatamClass,
    required this.notes,
    required this.practiceCount,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = practiceCount == 4;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SadhanaHistoryScreen.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: allDone
              ? SadhanaHistoryScreen.green.withOpacity(0.22)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DateBadge(day: day, month: month, allDone: allDone),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: SadhanaHistoryScreen.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      allDone
                          ? 'Beautiful — all practices completed'
                          : '$practiceCount of 4 practices completed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: allDone
                            ? SadhanaHistoryScreen.green
                            : SadhanaHistoryScreen.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (allDone)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: SadhanaHistoryScreen.green,
                    size: 21,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Japa',
                  value: '$japaRounds',
                  suffix: 'rounds',
                  icon: Icons.spa_rounded,
                  color: SadhanaHistoryScreen.accent,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MetricChip(
                  label: 'Reading',
                  value: '$readingMinutes',
                  suffix: 'min',
                  icon: Icons.menu_book_rounded,
                  color: SadhanaHistoryScreen.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _MetricChip(
                  label: 'Service',
                  value: '$serviceMinutes',
                  suffix: 'min',
                  icon: Icons.volunteer_activism_rounded,
                  color: SadhanaHistoryScreen.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PracticePill(
                label: 'Mangala Arati',
                done: mangalaArati,
                color: SadhanaHistoryScreen.primary,
              ),
              _PracticePill(
                label: 'Tulasi Puja',
                done: tulasiPuja,
                color: SadhanaHistoryScreen.green,
              ),
              _PracticePill(
                label: 'Guru Puja',
                done: guruPuja,
                color: SadhanaHistoryScreen.pink,
              ),
              _PracticePill(
                label: 'Bhagavatam Class',
                done: bhagavatamClass,
                color: SadhanaHistoryScreen.accent,
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: SadhanaHistoryScreen.primary.withOpacity(0.08),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: SadhanaHistoryScreen.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        color: SadhanaHistoryScreen.textMuted,
                        height: 1.45,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String day;
  final String month;
  final bool allDone;

  const _DateBadge({
    required this.day,
    required this.month,
    required this.allDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? const [Color(0xFF22C55E), Color(0xFF16A34A)]
              : const [
                  SadhanaHistoryScreen.primary,
                  SadhanaHistoryScreen.primaryDark,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            month,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            day,
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

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            suffix,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticePill extends StatelessWidget {
  final String label;
  final bool done;
  final Color color;

  const _PracticePill({
    required this.label,
    required this.done,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = done ? color : SadhanaHistoryScreen.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: done
            ? color.withOpacity(0.12)
            : SadhanaHistoryScreen.textMuted.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: effectiveColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
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
            color: SadhanaHistoryScreen.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 58,
                color: SadhanaHistoryScreen.primary,
              ),
              SizedBox(height: 14),
              Text(
                'No sadhana entries yet',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: SadhanaHistoryScreen.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Submit your daily sadhana and your devotional journey will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: SadhanaHistoryScreen.textMuted,
                  height: 1.45,
                ),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 620,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SadhanaHistoryScreen.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                'Could not load sadhana history.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SadhanaHistoryScreen.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
