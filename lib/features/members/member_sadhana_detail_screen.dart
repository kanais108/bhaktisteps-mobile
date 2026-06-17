import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../sadhana/sadhana_provider.dart';
import '../users/user_session_provider.dart';

class MemberSadhanaDetailScreen extends ConsumerStatefulWidget {
  final UserModel member;

  const MemberSadhanaDetailScreen({super.key, required this.member});

  @override
  ConsumerState<MemberSadhanaDetailScreen> createState() =>
      _MemberSadhanaDetailScreenState();
}

class _MemberSadhanaDetailScreenState
    extends ConsumerState<MemberSadhanaDetailScreen> {
  late DateTime fromDate;
  late DateTime toDate;

  bool isDownloading = false;
  bool isEmailing = false;
  bool isLoadingEntries = false;
  Map<String, dynamic>? summary;
  List<dynamic> entries = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    toDate = DateTime(now.year, now.month, now.day);
    fromDate = toDate.subtract(const Duration(days: 30));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMemberSadhanaHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;

    return Scaffold(
      appBar: AppBar(title: const Text('Member Sadhana')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MemberHeader(member: member),
          const SizedBox(height: 20),
          _DateRangeCard(
            fromDate: fromDate,
            toDate: toDate,
            onSelectRange: _selectDateRange,
          ),
          const SizedBox(height: 20),
          _ReportActionsCard(
            isDownloading: isDownloading,
            isEmailing: isEmailing,
            onDownload: _downloadReport,
            onEmail: _emailReport,
          ),
          const SizedBox(height: 20),
          _SadhanaEntriesCard(
            isLoading: isLoadingEntries,
            entries: entries,
            summary: summary,
          ),
          const SizedBox(height: 20),
          _InfoCard(memberName: member.fullName),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
    );

    if (picked == null) return;

    setState(() {
      fromDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      toDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });

    await _loadMemberSadhanaHistory();
  }

  Future<void> _downloadReport() async {
    if (isDownloading) return;

    final selectedUser = ref.read(selectedUserProvider);

    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to download the report.'),
        ),
      );
      return;
    }

    setState(() {
      isDownloading = true;
    });

    try {
      final service = ref.read(sadhanaServiceProvider);

      await service.exportAndOpenMemberSadhanaReport(
        facilitatorUserId: selectedUser.id,
        memberUserId: widget.member.id,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member Sadhana report downloaded.')),
      );
    } catch (error) {
      debugPrint('Member report download error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to download report. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  Future<void> _emailReport() async {
    if (isEmailing) return;

    final selectedUser = ref.read(selectedUserProvider);

    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to email the report.'),
        ),
      );
      return;
    }

    final email = selectedUser.email?.trim();

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account does not have an email address.'),
        ),
      );
      return;
    }

    setState(() {
      isEmailing = true;
    });

    try {
      final service = ref.read(sadhanaServiceProvider);

      await service.emailMemberSadhanaReport(
        facilitatorUserId: selectedUser.id,
        memberUserId: widget.member.id,
        email: email,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member Sadhana report emailed successfully.'),
        ),
      );
    } catch (error) {
      debugPrint('Member report email error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to email report. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isEmailing = false;
        });
      }
    }
  }

  Future<void> _loadMemberSadhanaHistory() async {
    final selectedUser = ref.read(selectedUserProvider);

    if (selectedUser == null) {
      return;
    }

    setState(() {
      isLoadingEntries = true;
    });

    try {
      final service = ref.read(sadhanaServiceProvider);

      final data = await service.getMemberSadhanaHistory(
        facilitatorUserId: selectedUser.id,
        memberUserId: widget.member.id,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (!mounted) return;

      setState(() {
        summary = Map<String, dynamic>.from(data['summary'] as Map? ?? {});
        entries = List<dynamic>.from(data['entries'] as List? ?? []);
      });
    } catch (error) {
      debugPrint('Member Sadhana history error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load member Sadhana entries.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingEntries = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

class _MemberHeader extends StatelessWidget {
  final UserModel member;

  const _MemberHeader({required this.member});

  @override
  Widget build(BuildContext context) {
    final email = member.email?.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                _initials(member.fullName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Devotee',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _DateRangeCard extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback onSelectRange;

  const _DateRangeCard({
    required this.fromDate,
    required this.toDate,
    required this.onSelectRange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Period',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateBox(label: 'From', value: _formatDate(fromDate)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(label: 'To', value: _formatDate(toDate)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSelectRange,
                icon: const Icon(Icons.date_range),
                label: const Text('Change Date Range'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String value;

  const _DateBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ReportActionsCard extends StatelessWidget {
  final bool isDownloading;
  final bool isEmailing;
  final VoidCallback onDownload;
  final VoidCallback onEmail;

  const _ReportActionsCard({
    required this.isDownloading,
    required this.isEmailing,
    required this.onDownload,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sadhana Report',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Download or email this member’s Sadhana report for the selected period.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isDownloading ? null : onDownload,
                icon: isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  isDownloading ? 'Downloading...' : 'Download Excel',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isEmailing ? null : onEmail,
                icon: isEmailing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.email_outlined),
                label: Text(isEmailing ? 'Sending...' : 'Email Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SadhanaEntriesCard extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> entries;
  final Map<String, dynamic>? summary;

  const _SadhanaEntriesCard({
    required this.isLoading,
    required this.entries,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final totalEntries = (summary?['totalEntries'] as num?)?.toInt() ?? 0;
    final averageJapaRounds =
        (summary?['averageJapaRounds'] as num?)?.toDouble() ?? 0;
    final totalReadingMinutes =
        (summary?['totalReadingMinutes'] as num?)?.toInt() ?? 0;
    final totalServiceMinutes =
        (summary?['totalServiceMinutes'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sadhana Entries',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visible daily Sadhana entries for the selected period.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          label: 'Entries',
                          value: '$totalEntries',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryBox(
                          label: 'Avg Japa',
                          value: averageJapaRounds.toStringAsFixed(1),
                          icon: Icons.spa_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          label: 'Reading',
                          value: '$totalReadingMinutes min',
                          icon: Icons.menu_book_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryBox(
                          label: 'Service',
                          value: '$totalServiceMinutes min',
                          icon: Icons.volunteer_activism_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (entries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'No Sadhana entries found for the selected date range.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...entries.map((entry) {
                      return _SadhanaEntryTile(
                        entry: Map<String, dynamic>.from(entry as Map),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _SadhanaEntryTile extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _SadhanaEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final entryDate = entry['entryDate']?.toString() ?? '';
    final japaRounds = (entry['japaRounds'] as num?)?.toInt() ?? 0;
    final readingMinutes = (entry['readingMinutes'] as num?)?.toInt() ?? 0;
    final serviceMinutes = (entry['serviceMinutes'] as num?)?.toInt() ?? 0;
    final sleptAt = entry['sleptAt']?.toString();
    final wokeUpAt = entry['wokeUpAt']?.toString();
    final notes = entry['notes']?.toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDisplayDate(entryDate),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: 'Japa', value: '$japaRounds rounds'),
              _Pill(label: 'Reading', value: '$readingMinutes min'),
              _Pill(label: 'Service', value: '$serviceMinutes min'),
              _BoolPill(
                label: 'Mangala Arati',
                value: entry['mangalaArati'] == true,
              ),
              _BoolPill(
                label: 'Tulasi Puja',
                value: entry['tulasiPuja'] == true,
              ),
              _BoolPill(label: 'Guru Puja', value: entry['guruPuja'] == true),
              _BoolPill(
                label: 'Bhagavatam',
                value: entry['bhagavatamClass'] == true,
              ),
            ],
          ),
          if ((sleptAt != null && sleptAt.isNotEmpty) ||
              (wokeUpAt != null && wokeUpAt.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Text(
              'Slept: ${sleptAt ?? '-'} • Woke: ${wokeUpAt ?? '-'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (notes != null && notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(notes, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  static String _formatDisplayDate(String value) {
    if (value.isEmpty) return 'Unknown date';

    try {
      final date = DateTime.parse(value);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return value;
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BoolPill extends StatelessWidget {
  final String label;
  final bool value;

  const _BoolPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: ${value ? 'Yes' : 'No'}'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String memberName;

  const _InfoCard({required this.memberName});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This report is generated for $memberName based on the selected date range.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
