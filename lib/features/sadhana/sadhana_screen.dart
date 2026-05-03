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
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFF59E0B);
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
      } else if (e.response?.data is Map<String, dynamic>) {
        final data = e.response?.data as Map<String, dynamic>;
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
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: softCard,
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, color: primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primary, width: 1.3),
      ),
    );
  }

  Widget _sectionCard({
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _metricField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration(label: label).copyWith(suffixText: suffix),
      ),
    );
  }

  Widget _practiceTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: textDark),
        ),
        value: value,
        activeColor: primary,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(selectedUserProvider);
    final todayAsync = ref.watch(sadhanaTodayProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('My Sadhana'),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                          color: const Color(0xFFEFF6FF),
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
                        'Please log in to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textMuted),
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
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  todayAsync.when(
                    data: (done) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: done
                              ? const [Color(0xFFE6F4EA), Color(0xFFCFF3D6)]
                              : const [Color(0xFFEFF6FF), Color(0xFFDCEAFE)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              done
                                  ? Icons.check_circle_rounded
                                  : Icons.self_improvement_rounded,
                              color: done ? Colors.green : primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              done
                                  ? 'Today’s sadhana is already submitted.'
                                  : 'Complete and submit today’s sadhana.',
                              style: const TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  _sectionCard(
                    title: 'Daily Entry',
                    subtitle: 'Record the essentials of your day’s practice.',
                    children: [
                      TextFormField(
                        controller: entryDateController,
                        readOnly: true,
                        onTap: _pickEntryDate,
                        decoration: _inputDecoration(
                          label: 'Entry Date',
                          suffixIcon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _metricField(
                            controller: japaRoundsController,
                            label: 'Japa',
                            suffix: 'rounds',
                          ),
                          const SizedBox(width: 12),
                          _metricField(
                            controller: readingMinutesController,
                            label: 'Reading',
                            suffix: 'min',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: serviceMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Service Minutes',
                        ).copyWith(suffixText: 'min'),
                      ),
                    ],
                  ),
                  _sectionCard(
                    title: 'Practices',
                    subtitle:
                        'Mark the devotional activities you attended today.',
                    children: [
                      _practiceTile(
                        title: 'Mangala Arati',
                        value: mangalaArati,
                        onChanged: (value) {
                          setState(() => mangalaArati = value);
                        },
                      ),
                      _practiceTile(
                        title: 'Tulasi Puja',
                        value: tulasiPuja,
                        onChanged: (value) {
                          setState(() => tulasiPuja = value);
                        },
                      ),
                      _practiceTile(
                        title: 'Guru Puja',
                        value: guruPuja,
                        onChanged: (value) {
                          setState(() => guruPuja = value);
                        },
                      ),
                      _practiceTile(
                        title: 'Bhagavatam Class',
                        value: bhagavatamClass,
                        onChanged: (value) {
                          setState(() => bhagavatamClass = value);
                        },
                      ),
                    ],
                  ),
                  _sectionCard(
                    title: 'Reflection',
                    subtitle: 'Add any note or observation from your day.',
                    children: [
                      TextFormField(
                        controller: notesController,
                        maxLines: 4,
                        decoration: _inputDecoration(label: 'Notes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        isSubmitting ? 'Submitting...' : 'Submit Sadhana',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
