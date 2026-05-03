import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../events/events_provider.dart';
import '../users/user_session_provider.dart';
import 'attendance_bulk_provider.dart';
import 'attendance_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? selectedGroupId;
  String? selectedEventId;
  DateTime selectedDate = DateTime.now();
  bool isSubmitting = false;
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
          return 'Invalid request. Please check the attendance details.';
        case 401:
          return 'Session expired. Please log in again.';
        case 403:
          return 'You do not have permission to save attendance.';
        case 404:
          return 'Attendance resource was not found.';
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
      helpText: 'Select Attendance Date',
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
      selectedEventId = null;
      attendanceMap.clear();
      remarksMap.clear();
      searchQuery = '';
    });
  }

  void markAllPresent(List<dynamic> members) {
    setState(() {
      for (final member in members) {
        final userId = member.userId as String;
        attendanceMap[userId] = true;
      }
    });
  }

  void markAllAbsent(List<dynamic> members) {
    setState(() {
      for (final member in members) {
        final userId = member.userId as String;
        attendanceMap[userId] = false;
      }
    });
  }

  int _presentCount(List<dynamic> members) {
    return members.where((member) {
      final userId = member.userId as String;
      return attendanceMap[userId] ?? true;
    }).length;
  }

  int _absentCount(List<dynamic> members) {
    return members.length - _presentCount(members);
  }

  Future<void> submitBulkAttendance() async {
    final selectedUser = ref.read(selectedUserProvider);

    if (selectedUser == null) {
      _showSnack('Please log in again', isError: true);
      return;
    }

    if (!selectedUser.isLeader) {
      _showSnack('You do not have access to attendance', isError: true);
      return;
    }

    if (selectedGroupId == null || selectedGroupId!.isEmpty) {
      _showSnack('Please select a group', isError: true);
      return;
    }

    if (selectedEventId == null || selectedEventId!.isEmpty) {
      _showSnack('Please select an event', isError: true);
      return;
    }

    final members = await ref.read(
      groupMembersProvider(selectedGroupId!).future,
    );

    if (members.isEmpty) {
      _showSnack('No members found for this group', isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final attendanceService = ref.read(bulkAttendanceServiceProvider);

      final records = members.map((member) {
        final userId = member.userId as String;
        return {
          'userId': userId,
          'status': (attendanceMap[userId] ?? true) ? 'present' : 'absent',
          'remarks': (remarksMap[userId]?.trim().isEmpty ?? true)
              ? null
              : remarksMap[userId]!.trim(),
        };
      }).toList();

      await attendanceService.bulkCreateOrUpdateAttendance({
        'eventId': selectedEventId,
        'records': records,
      });

      ref.invalidate(attendanceProvider);
      ref.invalidate(eventsProvider);

      if (!mounted) return;

      _showSnack(
        'Attendance saved for ${DateFormat('dd MMM yyyy').format(selectedDate)}',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        _friendlyError(e, 'Failed to save attendance. Please try again.'),
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

  Widget _accessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _sectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 38,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Attendance Access Restricted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Attendance can only be recorded by authorized leaders in your hierarchy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
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
              'You can record attendance only for programs and members available within your assigned hierarchy.',
              style: TextStyle(color: textDark, fontSize: 13, height: 1.4),
            ),
          ),
        ],
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
    final userId = member.userId as String;
    final fullName = member.fullName as String;

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
              key: ValueKey('remarks_$userId'),
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
    final hasSelection = selectedGroupId != null && selectedEventId != null;
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
                onPressed: isSubmitting || !hasSelection
                    ? null
                    : submitBulkAttendance,
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
                        'Save Attendance',
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
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: Text('Please log in first')),
      );
    }

    if (!selectedUser.isLeader) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: const Text('Attendance')),
        body: _accessDeniedView(),
      );
    }

    final groupsAsync = ref.watch(scopedGroupsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final membersAsync = selectedGroupId == null
        ? null
        : ref.watch(groupMembersProvider(selectedGroupId!));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _emptyState(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load groups',
          subtitle: 'Please check your connection and try again.',
        ),
        data: (groups) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _infoBanner(),
                    const SizedBox(height: 16),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Choose the date, group, and event for which attendance is being recorded.',
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                          const SizedBox(height: 16),
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
                                          'Attendance Date',
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
                          DropdownButtonFormField<String>(
                            value: selectedGroupId,
                            decoration: InputDecoration(
                              labelText: 'Select Group',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            items: groups
                                .map<DropdownMenuItem<String>>(
                                  (g) => DropdownMenuItem<String>(
                                    value: g.id as String,
                                    child: Text(g.name as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedGroupId = value;
                                selectedEventId = null;
                                attendanceMap.clear();
                                remarksMap.clear();
                                searchQuery = '';
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          eventsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) => const Text(
                              'Unable to load events',
                              style: TextStyle(color: danger),
                            ),
                            data: (events) {
                              final filteredEvents = events.where((e) {
                                return _isSameDate(
                                  e.startsAt.toLocal(),
                                  selectedDate,
                                );
                              }).toList();

                              return DropdownButtonFormField<String>(
                                value: selectedEventId,
                                decoration: InputDecoration(
                                  labelText: 'Select Event',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                items: filteredEvents
                                    .map(
                                      (e) => DropdownMenuItem<String>(
                                        value: e.id,
                                        child: Text(e.title),
                                      ),
                                    )
                                    .toList(),
                                onChanged: filteredEvents.isEmpty
                                    ? null
                                    : (value) {
                                        setState(() {
                                          selectedEventId = value;
                                        });
                                      },
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          eventsAsync.maybeWhen(
                            data: (events) {
                              final filteredEvents = events.where((e) {
                                return _isSameDate(
                                  e.startsAt.toLocal(),
                                  selectedDate,
                                );
                              }).toList();

                              if (filteredEvents.isNotEmpty) {
                                return const SizedBox.shrink();
                              }

                              return const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  'No events found for the selected date.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                ),
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      child: selectedGroupId == null
                          ? _emptyState(
                              icon: Icons.groups_rounded,
                              title: 'Select a group',
                              subtitle:
                                  'Members will appear here after selecting a group.',
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
                                final allMembers = membersRaw as List<dynamic>;
                                final members = allMembers.where((m) {
                                  final name = (m.fullName as String)
                                      .toLowerCase();
                                  return name.contains(searchQuery);
                                }).toList();

                                if (allMembers.isEmpty) {
                                  return _emptyState(
                                    icon: Icons.person_off_rounded,
                                    title: 'No members found',
                                    subtitle:
                                        'This group does not have members yet.',
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Members',
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
                      data: (members) =>
                          _bottomSaveBar(members as List<dynamic>),
                      orElse: () => _bottomSaveBar(null),
                    ),
            ],
          );
        },
      ),
    );
  }
}
