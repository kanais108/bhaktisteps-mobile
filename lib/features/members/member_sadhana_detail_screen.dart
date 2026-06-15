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

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    toDate = DateTime(now.year, now.month, now.day);
    fromDate = toDate.subtract(const Duration(days: 30));
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
