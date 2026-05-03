import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/dashboard_provider.dart';
import '../users/user_selector_screen.dart';
import '../users/user_session_provider.dart';
import 'sadhana_history_provider.dart';
import 'sadhana_provider.dart';
import 'sadhana_streak_provider.dart';
import 'sadhana_today_provider.dart';

class SadhanaScreen extends ConsumerStatefulWidget {
  const SadhanaScreen({super.key});

  @override
  ConsumerState<SadhanaScreen> createState() => _SadhanaScreenState();
}

class _SadhanaScreenState extends ConsumerState<SadhanaScreen> {
  final entryDateController = TextEditingController();
  final japaRoundsController = TextEditingController(text: '16');
  final readingMinutesController = TextEditingController(text: '0');
  final serviceMinutesController = TextEditingController(text: '0');
  final notesController = TextEditingController();

  bool mangalaArati = false;
  bool tulasiPuja = false;
  bool guruPuja = false;
  bool bhagavatamClass = false;
  bool isSubmitting = false;

  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFF59E0B);
  static const Color green = Color(0xFF16A34A);
  static const Color pink = Color(0xFFEC4899);
  static const Color softCard = Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    entryDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
  }

  @override
  void dispose() {
    entryDateController.dispose();
    japaRoundsController.dispose();
    readingMinutesController.dispose();
    serviceMinutesController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    entryDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    japaRoundsController.text = '16';
    readingMinutesController.text = '0';
    serviceMinutesController.text = '0';
    notesController.clear();

    mangalaArati = false;
    tulasiPuja = false;
    guruPuja = false;
    bhagavatamClass = false;
  }

  Future<void> _refreshData() async {
    ref.invalidate(sadhanaTodayProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(sadhanaHistoryProvider);
    ref.invalidate(sadhanaStreakProvider);

    try {
      await ref.read(sadhanaTodayProvider.future);
    } catch (_) {}

    try {
      await ref.read(sadhanaStreakProvider.future);
    } catch (_) {}
  }

  Future<void> _pickEntryDate() async {
    final initialDate =
        DateTime.tryParse(entryDateController.text) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      helpText: 'Select Entry Date',
    );

    if (picked != null) {
      setState(() {
        entryDateController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> submitForm() async {
    FocusScope.of(context).unfocus();

    final selectedUser = ref.read(selectedUserProvider);
    if (selectedUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in again')));
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final service = ref.read(sadhanaServiceProvider);

      await service.createSadhana({
        'userId': selectedUser.id,
        'entryDate': entryDateController.text.trim(),
        'japaRounds': int.tryParse(japaRoundsController.text.trim()) ?? 0,
        'mangalaArati': mangalaArati,
        'tulasiPuja': tulasiPuja,
        'guruPuja': guruPuja,
        'bhagavatamClass': bhagavatamClass,
        'readingMinutes':
            int.tryParse(readingMinutesController.text.trim()) ?? 0,
        'serviceMinutes':
            int.tryParse(serviceMinutesController.text.trim()) ?? 0,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      });

      ref.invalidate(sadhanaTodayProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(sadhanaHistoryProvider);
      ref.invalidate(sadhanaStreakProvider);

      if (!mounted) return;

      setState(() {
        _resetForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sadhana submitted successfully')),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Failed to submit sadhana';

      if (e.response?.statusCode == 409) {
        message = 'Sadhana already submitted for this user and date';
      } else if (e.response?.data is Map) {
        final data = e.response?.data as Map;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      filled: true,
      fillColor: softCard,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primary.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primary, width: 1.3),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _metricField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    String? helperText,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration(
          label: label,
          helperText: helperText,
        ).copyWith(suffixText: suffix),
      ),
    );
  }

  Widget _practiceTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.10) : softCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.28) : Colors.transparent,
        ),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, color: textDark),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: textMuted, fontSize: 12.5),
        ),
        value: value,
        activeColor: activeColor,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  int get _practiceCount {
    int count = 0;
    if (mangalaArati) count++;
    if (tulasiPuja) count++;
    if (guruPuja) count++;
    if (bhagavatamClass) count++;
    return count;
  }

  String _statusMessage(bool done, int streak) {
    if (done) {
      if (streak >= 7)
        return 'Wonderful consistency! Keep your devotional streak glowing.';
      return 'Today is complete. Stay steady and joyful in your practice.';
    }

    if (streak >= 7) {
      return 'You are doing beautifully. Keep your streak alive today.';
    }

    return 'A little sincere effort every day creates deep spiritual strength.';
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(selectedUserProvider);
    final todayAsync = ref.watch(sadhanaTodayProvider);
    final streakAsync = ref.watch(sadhanaStreakProvider);

    final todayDone = todayAsync.maybeWhen(
      data: (done) => done,
      orElse: () => false,
    );

    final streakCount = streakAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('My Sadhana'),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: selectedUser == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
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
                          Icons.person_search_rounded,
                          size: 36,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No devotee selected',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please log in to continue and begin your daily practice.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textMuted, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserSelectorScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: todayDone
                              ? const [Color(0xFFE8F7EC), Color(0xFFD8F5E1)]
                              : const [Color(0xFF4F7BFF), Color(0xFF7A5AF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: (todayDone ? green : primary).withOpacity(
                              0.18,
                            ),
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
                                  color: Colors.white.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  todayDone
                                      ? Icons.check_circle_rounded
                                      : Icons.self_improvement_rounded,
                                  color: todayDone ? green : Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todayDone
                                          ? 'Today’s offering is complete'
                                          : 'Nourish your daily practice',
                                      style: TextStyle(
                                        color: todayDone
                                            ? textDark
                                            : Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _statusMessage(todayDone, streakCount),
                                      style: TextStyle(
                                        color: todayDone
                                            ? textMuted
                                            : Colors.white.withOpacity(0.92),
                                        fontSize: 13.5,
                                        height: 1.4,
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
                                  label: 'Current streak',
                                  value:
                                      '$streakCount day${streakCount == 1 ? '' : 's'}',
                                  icon: Icons.local_fire_department_rounded,
                                  iconColor: accent,
                                  background: Colors.white.withOpacity(
                                    todayDone ? 0.90 : 0.16,
                                  ),
                                  textColor: todayDone
                                      ? textDark
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryStat(
                                  label: 'Practices today',
                                  value: '$_practiceCount / 4',
                                  icon: Icons.favorite_rounded,
                                  iconColor: pink,
                                  background: Colors.white.withOpacity(
                                    todayDone ? 0.90 : 0.16,
                                  ),
                                  textColor: todayDone
                                      ? textDark
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionCard(
                      icon: Icons.calendar_month_rounded,
                      iconBg: primarySoft,
                      iconColor: primary,
                      title: 'Daily Entry',
                      subtitle:
                          'Capture the essentials of your daily devotional practice.',
                      children: [
                        TextFormField(
                          controller: entryDateController,
                          readOnly: true,
                          onTap: _pickEntryDate,
                          decoration: _inputDecoration(
                            label: 'Entry Date',
                            helperText: 'Tap to choose the date for this entry',
                            suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _metricField(
                              controller: japaRoundsController,
                              label: 'Japa',
                              suffix: 'rounds',
                              helperText: 'Daily target is often 16',
                            ),
                            const SizedBox(width: 12),
                            _metricField(
                              controller: readingMinutesController,
                              label: 'Reading',
                              suffix: 'min',
                              helperText: 'Scripture reading time',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: serviceMinutesController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'Service Minutes',
                            helperText: 'Time spent in seva today',
                          ).copyWith(suffixText: 'min'),
                        ),
                      ],
                    ),
                    _sectionCard(
                      icon: Icons.auto_awesome_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: accent,
                      title: 'Practices',
                      subtitle:
                          'Mark the devotional activities you attended today.',
                      children: [
                        _practiceTile(
                          title: 'Mangala Arati',
                          subtitle: 'Begin the day with sacred morning worship',
                          value: mangalaArati,
                          activeColor: primary,
                          onChanged: (value) =>
                              setState(() => mangalaArati = value),
                        ),
                        _practiceTile(
                          title: 'Tulasi Puja',
                          subtitle:
                              'Offer your prayers and devotion with gratitude',
                          value: tulasiPuja,
                          activeColor: green,
                          onChanged: (value) =>
                              setState(() => tulasiPuja = value),
                        ),
                        _practiceTile(
                          title: 'Guru Puja',
                          subtitle: 'Honor the guru-parampara with devotion',
                          value: guruPuja,
                          activeColor: pink,
                          onChanged: (value) =>
                              setState(() => guruPuja = value),
                        ),
                        _practiceTile(
                          title: 'Bhagavatam Class',
                          subtitle:
                              'Nourish the heart through hearing and reflection',
                          value: bhagavatamClass,
                          activeColor: accent,
                          onChanged: (value) =>
                              setState(() => bhagavatamClass = value),
                        ),
                      ],
                    ),
                    _sectionCard(
                      icon: Icons.edit_note_rounded,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Reflection',
                      subtitle:
                          'Write one thought, gratitude, or insight from your day.',
                      children: [
                        TextFormField(
                          controller: notesController,
                          maxLines: 5,
                          decoration: _inputDecoration(
                            label: 'Notes',
                            helperText:
                                'Optional, but great for building mindful reflection',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSubmitting
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : const [primary, primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSubmitting
                            ? const []
                            : [
                                BoxShadow(
                                  color: primary.withOpacity(0.24),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : submitForm,
                        icon: Icon(
                          isSubmitting
                              ? Icons.hourglass_top_rounded
                              : Icons.favorite_rounded,
                        ),
                        label: Text(
                          isSubmitting ? 'Submitting...' : 'Submit Sadhana',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: white,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color textColor;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor.withOpacity(0.82),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
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
