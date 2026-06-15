import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../sadhana/sadhana_provider.dart';
import '../users/user_session_provider.dart';
import '../users/users_provider.dart';
import 'member_sadhana_detail_screen.dart';

class MemberSadhanaScreen extends ConsumerStatefulWidget {
  const MemberSadhanaScreen({super.key});

  @override
  ConsumerState<MemberSadhanaScreen> createState() =>
      _MemberSadhanaScreenState();
}

class _MemberSadhanaScreenState extends ConsumerState<MemberSadhanaScreen> {
  late DateTime fromDate;
  late DateTime toDate;

  bool isDownloadingAll = false;
  bool isEmailingAll = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    toDate = DateTime(now.year, now.month, now.day);
    fromDate = toDate.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(activeDevoteeMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Members Sadhana')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeDevoteeMembersProvider);
          await ref.read(activeDevoteeMembersProvider.future);
        },
        child: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              Icon(
                Icons.error_outline,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load members',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please pull down to refresh or try again later.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          data: (members) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AllMembersReportCard(
                  fromDate: fromDate,
                  toDate: toDate,
                  isDownloading: isDownloadingAll,
                  isEmailing: isEmailingAll,
                  onSelectRange: _selectDateRange,
                  onDownload: members.isEmpty ? null : _downloadAllMembers,
                  onEmail: members.isEmpty ? null : _emailAllMembers,
                ),
                const SizedBox(height: 18),
                Text(
                  'Members',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${members.length} active devotee${members.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                if (members.isEmpty)
                  _EmptyMembersView()
                else
                  ...members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MemberCard(
                        member: member,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MemberSadhanaDetailScreen(member: member),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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

  Future<void> _downloadAllMembers() async {
    if (isDownloadingAll) return;

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
      isDownloadingAll = true;
    });

    try {
      final service = ref.read(sadhanaServiceProvider);

      await service.exportAndOpenAllMembersSadhanaReport(
        facilitatorUserId: selectedUser.id,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All members Sadhana report downloaded.')),
      );
    } catch (error) {
      debugPrint('All members report download error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to download all members report.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDownloadingAll = false;
        });
      }
    }
  }

  Future<void> _emailAllMembers() async {
    if (isEmailingAll) return;

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
      isEmailingAll = true;
    });

    try {
      final service = ref.read(sadhanaServiceProvider);

      await service.emailAllMembersSadhanaReport(
        facilitatorUserId: selectedUser.id,
        email: email,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All members Sadhana report emailed successfully.'),
        ),
      );
    } catch (error) {
      debugPrint('All members report email error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to email all members report.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isEmailingAll = false;
        });
      }
    }
  }
}

class _AllMembersReportCard extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final bool isDownloading;
  final bool isEmailing;
  final VoidCallback onSelectRange;
  final VoidCallback? onDownload;
  final VoidCallback? onEmail;

  const _AllMembersReportCard({
    required this.fromDate,
    required this.toDate,
    required this.isDownloading,
    required this.isEmailing,
    required this.onSelectRange,
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
              'All Members Report',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Export or email Sadhana report for all members under your leadership.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 10),
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
                  isDownloading ? 'Downloading...' : 'Download All Members',
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
                label: Text(
                  isEmailing ? 'Sending...' : 'Email All Members Report',
                ),
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

class _EmptyMembersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No members found',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Once devotees are assigned under your leadership, they will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel member;
  final VoidCallback onTap;

  const _MemberCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final email = member.email?.trim();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  _initials(member.fullName),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Devotee',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
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
