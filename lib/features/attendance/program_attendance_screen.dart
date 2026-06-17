import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../users/user_session_provider.dart';
import 'attendance_bulk_provider.dart';

class ProgramAttendanceScreen extends ConsumerStatefulWidget {
  const ProgramAttendanceScreen({super.key});

  @override
  ConsumerState<ProgramAttendanceScreen> createState() =>
      _ProgramAttendanceScreenState();
}

class _ProgramAttendanceScreenState
    extends ConsumerState<ProgramAttendanceScreen> {
  String? selectedBatchId;
  String? selectedSessionId;
  DateTime selectedDate = DateTime.now();

  bool isSubmitting = false;
  bool isCreatingSession = false;
  String searchQuery = '';

  final Map<String, bool> attendanceMap = {};
  final Map<String, String> remarksMap = {};

  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFE8F7EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFDC2626);

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  String _friendlyError(Object error, String fallback) {
    if (error is DioException) {
      final serverMessage = error.response?.data;

      if (serverMessage is Map && serverMessage['message'] != null) {
        return serverMessage['message'].toString();
      }

      switch (error.response?.statusCode) {
        case 400:
          return 'Invalid request. Please check the program session details.';
        case 401:
          return 'Session expired. Please log in again.';
        case 403:
          return 'You do not have permission to manage this program.';
        case 404:
          return 'Program attendance resource was not found.';
        case 500:
          return 'Server error while saving attendance. Please try again.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Connection timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection. Please try again.';
      }
    }

    return fallback;
  }

  Future<void> _pickAttendanceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Session Date',
    );

    if (picked == null) return;

    setState(() {
      selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  int _nextWeekNumber(List<dynamic> sessions) {
    if (sessions.isEmpty) return 1;

    final weekNumbers = sessions
        .map((session) => (session['weekNumber'] as num?)?.toInt() ?? 0)
        .where((value) => value > 0)
        .toList();

    if (weekNumbers.isEmpty) return 1;

    weekNumbers.sort();
    return weekNumbers.last + 1;
  }

  Future<void> _createSession(List<dynamic> sessions) async {
    if (selectedBatchId == null || selectedBatchId!.isEmpty) {
      _showSnack('Please select a program batch first', isError: true);
      return;
    }

    final weekController = TextEditingController(
      text: _nextWeekNumber(sessions).toString(),
    );

    final titleController = TextEditingController(
      text: 'Week ${_nextWeekNumber(sessions)}',
    );

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Create Program Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Session date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: weekController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Week Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (shouldCreate != true) return;

    final weekNumber = int.tryParse(weekController.text.trim());

    if (weekNumber == null || weekNumber < 1) {
      _showSnack('Please enter a valid week number', isError: true);
      return;
    }

    setState(() => isCreatingSession = true);

    try {
      final service = ref.read(bulkAttendanceServiceProvider);

      final session = await service.createProgramSession(
        batchId: selectedBatchId!,
        weekNumber: weekNumber,
        sessionDate: selectedDate,
        title: titleController.text,
      );

      if (!mounted) return;

      setState(() {
        selectedSessionId = session['id']?.toString();
        attendanceMap.clear();
        remarksMap.clear();
      });

      ref.invalidate(programBatchSessionsProvider(selectedBatchId!));

      _showSnack('Program session created.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        _friendlyError(error, 'Unable to create program session.'),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isCreatingSession = false);
      }
    }
  }

  void _applyExistingAttendance(List<dynamic> records) {
    for (final record in records) {
      final user = record['user'];

      final userId = user is Map
          ? user['id']?.toString()
          : record['userId']?.toString();

      if (userId == null || userId.isEmpty) continue;

      attendanceMap[userId] = record['status'] == 'present';
      remarksMap[userId] = record['remarks']?.toString() ?? '';
    }
  }

  void markAllPresent(List<dynamic> members) {
    setState(() {
      for (final member in members) {
        final userId = member['userId']?.toString() ?? '';
        if (userId.isNotEmpty) {
          attendanceMap[userId] = true;
        }
      }
    });
  }

  void markAllAbsent(List<dynamic> members) {
    setState(() {
      for (final member in members) {
        final userId = member['userId']?.toString() ?? '';
        if (userId.isNotEmpty) {
          attendanceMap[userId] = false;
        }
      }
    });
  }

  int _presentCount(List<dynamic> members) {
    return members.where((member) {
      final userId = member['userId']?.toString() ?? '';
      return attendanceMap[userId] ?? true;
    }).length;
  }

  int _absentCount(List<dynamic> members) {
    return members.length - _presentCount(members);
  }

  Future<void> submitProgramAttendance(List<dynamic> members) async {
    final selectedUser = ref.read(selectedUserProvider);

    if (selectedUser == null) {
      _showSnack('Please log in again', isError: true);
      return;
    }

    if (!selectedUser.isLeader) {
      _showSnack('You do not have access to attendance', isError: true);
      return;
    }

    if (selectedBatchId == null || selectedBatchId!.isEmpty) {
      _showSnack('Please select a program batch', isError: true);
      return;
    }

    if (selectedSessionId == null || selectedSessionId!.isEmpty) {
      _showSnack('Please select or create a session', isError: true);
      return;
    }

    if (members.isEmpty) {
      _showSnack('No members found for this program batch', isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final service = ref.read(bulkAttendanceServiceProvider);

      final records = members.map((member) {
        final userId = member['userId']?.toString() ?? '';

        return {
          'userId': userId,
          'status': (attendanceMap[userId] ?? true) ? 'present' : 'absent',
          'remarks': (remarksMap[userId]?.trim().isEmpty ?? true)
              ? null
              : remarksMap[userId]!.trim(),
        };
      }).toList();

      await service.bulkCreateOrUpdateProgramAttendance(
        sessionId: selectedSessionId!,
        records: records,
      );

      ref.invalidate(programSessionAttendanceProvider(selectedSessionId!));

      if (!mounted) return;

      _showSnack('Program attendance saved successfully.');
    } catch (error) {
      if (!mounted) return;

      _showSnack(
        _friendlyError(error, 'Failed to save program attendance.'),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: textMuted, size: 38),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(dynamic member) {
    final userId = member['userId']?.toString() ?? '';
    final fullName = member['fullName']?.toString() ?? 'Unknown devotee';

    attendanceMap.putIfAbsent(userId, () => true);
    remarksMap.putIfAbsent(userId, () => '');

    final isPresent = attendanceMap[userId] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPresent
              ? success.withValues(alpha: 0.12)
              : warning.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primary, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPresent ? successSoft : warningSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      color: isPresent ? success : warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Absent',
                  style: TextStyle(
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: isPresent,
                  activeColor: primary,
                  onChanged: (value) {
                    setState(() {
                      attendanceMap[userId] = value;
                    });
                  },
                ),
                const Text(
                  'Present',
                  style: TextStyle(
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            TextFormField(
              key: ValueKey('program_remarks_$userId'),
              initialValue: remarksMap[userId] ?? '',
              decoration: InputDecoration(
                labelText: 'Remarks',
                hintText: 'Optional note',
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                remarksMap[userId] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSaveBar(List<dynamic>? members) {
    final hasSelection = selectedBatchId != null && selectedSessionId != null;
    final total = members?.length ?? 0;
    final present = members == null ? 0 : _presentCount(members);
    final absent = members == null ? 0 : _absentCount(members);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (members != null && total > 0) ...[
              Row(
                children: [
                  _summaryChip(
                    label: 'Present',
                    value: '$present',
                    color: success,
                    backgroundColor: successSoft,
                  ),
                  const SizedBox(width: 10),
                  _summaryChip(
                    label: 'Absent',
                    value: '$absent',
                    color: warning,
                    backgroundColor: warningSoft,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting || !hasSelection || members == null
                    ? null
                    : () => submitProgramAttendance(members),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: white,
                  disabledBackgroundColor: textMuted.withValues(alpha: 0.25),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: white,
                        ),
                      )
                    : const Text(
                        'Save Program Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(selectedUserProvider);

    if (selectedUser == null) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: const Text('Program Attendance')),
        body: const Center(child: Text('Please log in first')),
      );
    }

    if (!selectedUser.isLeader) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: const Text('Program Attendance')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Program attendance can only be recorded by authorized leaders.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final batchesAsync = ref.watch(programBatchesProvider);
    final sessionsAsync = selectedBatchId == null
        ? null
        : ref.watch(programBatchSessionsProvider(selectedBatchId!));
    final membersAsync = selectedBatchId == null
        ? null
        : ref.watch(programBatchMembersProvider(selectedBatchId!));
    final attendanceAsync = selectedSessionId == null
        ? null
        : ref.watch(programSessionAttendanceProvider(selectedSessionId!));

    attendanceAsync?.whenData((records) {
      _applyExistingAttendance(records);
    });

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Program Attendance'),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _emptyState(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load programs',
          subtitle: 'Please check your connection and try again.',
        ),
        data: (batches) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDCEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Use this for regular programs like Bhakti Steps. You do not need to create a separate Event every week.',
                              style: TextStyle(
                                color: textDark,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Program Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Choose a program batch and create or select a weekly session.',
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedBatchId,
                            decoration: InputDecoration(
                              labelText: 'Select Program Batch',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            items: batches.map<DropdownMenuItem<String>>((
                              batch,
                            ) {
                              final program = batch['program'];
                              final programName = program is Map
                                  ? program['name']?.toString() ?? 'Program'
                                  : 'Program';

                              final batchName =
                                  batch['name']?.toString() ?? 'Batch';

                              return DropdownMenuItem<String>(
                                value: batch['id']?.toString(),
                                child: Text('$programName - $batchName'),
                              );
                            }).toList(),
                            onChanged: batches.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedBatchId = value;
                                      selectedSessionId = null;
                                      attendanceMap.clear();
                                      remarksMap.clear();
                                      searchQuery = '';
                                    });
                                  },
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _pickAttendanceDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Session Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat(
                                            'EEEE, dd MMM yyyy',
                                          ).format(selectedDate),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          sessionsAsync == null
                              ? const SizedBox.shrink()
                              : sessionsAsync.when(
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (error, _) => const Text(
                                    'Unable to load sessions',
                                    style: TextStyle(color: danger),
                                  ),
                                  data: (sessions) {
                                    return Column(
                                      children: [
                                        DropdownButtonFormField<String>(
                                          value: selectedSessionId,
                                          decoration: InputDecoration(
                                            labelText: 'Select Session',
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFF),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          items: sessions
                                              .map<DropdownMenuItem<String>>((
                                                session,
                                              ) {
                                                final week =
                                                    (session['weekNumber']
                                                            as num?)
                                                        ?.toInt();

                                                final title =
                                                    session['title']
                                                        ?.toString() ??
                                                    'Week $week';

                                                final sessionDate =
                                                    session['sessionDate']
                                                        ?.toString()
                                                        .split('T')
                                                        .first ??
                                                    '';

                                                return DropdownMenuItem<String>(
                                                  value: session['id']
                                                      ?.toString(),
                                                  child: Text(
                                                    '$title • $sessionDate',
                                                  ),
                                                );
                                              })
                                              .toList(),
                                          onChanged: sessions.isEmpty
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    selectedSessionId = value;
                                                    attendanceMap.clear();
                                                    remarksMap.clear();
                                                  });
                                                },
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: isCreatingSession
                                                ? null
                                                : () =>
                                                      _createSession(sessions),
                                            icon: isCreatingSession
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(Icons.add),
                                            label: Text(
                                              isCreatingSession
                                                  ? 'Creating...'
                                                  : 'Create New Weekly Session',
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      child: selectedBatchId == null
                          ? _emptyState(
                              icon: Icons.school_outlined,
                              title: 'Select a program batch',
                              subtitle:
                                  'Members will appear after selecting a batch.',
                            )
                          : membersAsync!.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, _) => _emptyState(
                                icon: Icons.error_outline_rounded,
                                title: 'Unable to load members',
                                subtitle:
                                    'Please try again after checking your connection.',
                              ),
                              data: (membersRaw) {
                                final allMembers = membersRaw;
                                final members = allMembers.where((m) {
                                  final name =
                                      m['fullName']?.toString().toLowerCase() ??
                                      '';
                                  return name.contains(searchQuery);
                                }).toList();

                                if (allMembers.isEmpty) {
                                  return _emptyState(
                                    icon: Icons.person_off_rounded,
                                    title: 'No members found',
                                    subtitle:
                                        'This program batch does not have members yet.',
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Program Members',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: textDark,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              markAllAbsent(allMembers),
                                          child: const Text(
                                            'All Absent',
                                            style: TextStyle(
                                              color: warning,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              markAllPresent(allMembers),
                                          child: const Text(
                                            'All Present',
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${allMembers.length} members loaded',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search members...',
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: primary,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFF),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          searchQuery = value
                                              .trim()
                                              .toLowerCase();
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (members.isEmpty)
                                      _emptyState(
                                        icon: Icons.search_off_rounded,
                                        title: 'No matching members',
                                        subtitle:
                                            'Try searching with a different name.',
                                      )
                                    else
                                      ...members.map(_memberTile),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              membersAsync == null
                  ? _bottomSaveBar(null)
                  : membersAsync.maybeWhen(
                      data: (members) => _bottomSaveBar(members),
                      orElse: () => _bottomSaveBar(null),
                    ),
            ],
          );
        },
      ),
    );
  }
}
