import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../members/member_sadhana_screen.dart';
import '../sadhana/sadhana_history_provider.dart';
import '../sadhana/sadhana_history_screen.dart';
import '../sadhana/sadhana_streak_provider.dart';
import '../sadhana/sadhana_today_provider.dart';
import '../users/user_selector_screen.dart';
import '../users/user_session_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color white = Colors.white;
  static const Color accent = Color(0xFFF59E0B);
  static const Color green = Color(0xFF16A34A);
  static const Color purple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);

  bool _isLeadershipRole(String role) {
    return role == 'SUPER_ADMIN' ||
        role == 'CIRCLE_LEADER' ||
        role == 'SECTOR_LEADER' ||
        role == 'SERVANT_LEADER';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'CIRCLE_LEADER':
        return 'Circle Leader';
      case 'SECTOR_LEADER':
        return 'Sector Leader';
      case 'SERVANT_LEADER':
        return 'Servant Leader';
      default:
        return 'Devotee';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color _roleAccentColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return primary;
      case 'CIRCLE_LEADER':
        return green;
      case 'SECTOR_LEADER':
        return accent;
      case 'SERVANT_LEADER':
        return purple;
      default:
        return primary;
    }
  }

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconBg = const Color(0xFFEFF6FF),
    Color iconColor = primary,
    Color? trailingColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: trailingColor ?? textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showComingSoon(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reportIssue(BuildContext context, AppUser user) async {
    const supportEmail = 'rohitsingh949@gmail.com';

    final packageInfo = await PackageInfo.fromPlatform();

    final subject = 'Bhakti Steps App Issue';

    final body =
        '''
Hare Krishna,

I am facing this issue:


Device:
App Version: ${packageInfo.version} (${packageInfo.buildNumber})
User: ${user.fullName}
Email: ${user.email ?? ''}

Please describe what happened:
''';

    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open email app. Please contact support manually.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You can sign in again anytime to continue your devotional journey.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 14, height: 1.45),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await ref.read(selectedUserProvider.notifier).logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserSelectorScreen()),
      (route) => false,
    );
  }

  Future<void> _refreshProfileData(WidgetRef ref) async {
    ref.invalidate(sadhanaTodayProvider);
    ref.invalidate(sadhanaTodayEntryProvider);
    ref.invalidate(sadhanaHistoryProvider);
    ref.invalidate(sadhanaStreakProvider);

    try {
      await ref.read(sadhanaTodayProvider.future);
    } catch (_) {}

    try {
      await ref.read(sadhanaHistoryProvider.future);
    } catch (_) {}

    try {
      await ref.read(sadhanaStreakProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(selectedUserProvider);
    final todayAsync = ref.watch(sadhanaTodayProvider);
    final historyAsync = ref.watch(sadhanaHistoryProvider);
    final streakAsync = ref.watch(sadhanaStreakProvider);

    final todayDone = todayAsync.maybeWhen(
      data: (done) => done,
      orElse: () => false,
    );

    final historyCount = historyAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    final streakCount = streakAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        actions: selectedUser == null
            ? null
            : [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => _refreshProfileData(ref),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
      ),
      body: selectedUser == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _sectionCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 40,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No devotee selected',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please log in to continue your daily practice.',
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
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Go to Login',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _refreshProfileData(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _roleAccentColor(selectedUser.role),
                            primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _roleAccentColor(
                              selectedUser.role,
                            ).withOpacity(0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.self_improvement_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 11),
                              const Expanded(
                                child: Text(
                                  'Hare Krishna',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _initials(selectedUser.fullName),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    _showComingSoon(
                                      context,
                                      title: 'Photo Upload Coming Soon',
                                      message:
                                          'Soon you will be able to add a profile photo to personalize your Bhakti Steps journey.',
                                      icon: Icons.camera_alt_rounded,
                                      color: accent,
                                    );
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(17),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            selectedUser.fullName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 7),
                          if (selectedUser.email != null &&
                              selectedUser.email!.isNotEmpty)
                            Text(
                              selectedUser.email!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else if (selectedUser.phone != null &&
                              selectedUser.phone!.isNotEmpty)
                            Text(
                              selectedUser.phone!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 13),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.24),
                              ),
                            ),
                            child: Text(
                              _roleLabel(selectedUser.role),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              icon: todayDone
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_actions_rounded,
                              color: todayDone ? green : accent,
                              title: todayDone ? 'Done' : 'Pending',
                              subtitle: 'Today',
                              isLoading: todayAsync.isLoading,
                            ),
                          ),
                          Container(
                            height: 58,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.auto_stories_rounded,
                              color: primary,
                              title: '$historyCount',
                              subtitle: historyCount == 1 ? 'Entry' : 'Entries',
                              isLoading: historyAsync.isLoading,
                            ),
                          ),
                          Container(
                            height: 58,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.local_fire_department_rounded,
                              color: accent,
                              title: '$streakCount',
                              subtitle: streakCount == 1
                                  ? 'Day streak'
                                  : 'Day streak',
                              isLoading: streakAsync.isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Space',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your journey, review your activity, and keep moving forward.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _actionTile(
                            icon: Icons.history_rounded,
                            title: 'Sadhana History',
                            subtitle: 'View your submitted daily entries',
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: primary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SadhanaHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 18),
                          _actionTile(
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            subtitle: 'Profile editing can be enabled next',
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: purple,
                            onTap: () {
                              _showComingSoon(
                                context,
                                title: 'Edit Profile Coming Soon',
                                message:
                                    'Soon you will be able to update your details and personalize your profile.',
                                icon: Icons.edit_outlined,
                                color: purple,
                              );
                            },
                          ),
                          const Divider(height: 18),
                          _actionTile(
                            icon: Icons.bug_report_outlined,
                            title: 'Report an Issue',
                            subtitle: 'Send feedback or report a problem',
                            iconBg: const Color(0xFFFFF7ED),
                            iconColor: accent,
                            onTap: () => _reportIssue(context, selectedUser),
                          ),
                          const Divider(height: 18),
                          _actionTile(
                            icon: Icons.info_outline_rounded,
                            title: 'App Info',
                            subtitle: 'Bhakti Steps',
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: primary,
                            onTap: () {
                              _showComingSoon(
                                context,
                                title: 'Bhakti Steps',
                                message:
                                    'You are using the latest installed version of Bhakti Steps.',
                                icon: Icons.info_outline_rounded,
                                color: primary,
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.only(left: 62),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _AppVersionText(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLeadershipRole(selectedUser.role)) ...[
                      const SizedBox(height: 18),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Leadership Tools',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Care for devotees assigned under your leadership.',
                              style: TextStyle(
                                fontSize: 13,
                                color: textMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _actionTile(
                              icon: Icons.groups_rounded,
                              title: 'Members Sadhana',
                              subtitle:
                                  'View and export Sadhana reports for members',
                              iconBg: const Color(0xFFEFF6FF),
                              iconColor: primary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MemberSadhanaScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _sectionCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _actionTile(
                            icon: Icons.logout_rounded,
                            title: 'Log Out',
                            subtitle: 'Sign out from this device',
                            iconBg: const Color(0xFFFFF1F2),
                            iconColor: Colors.redAccent,
                            trailingColor: Colors.redAccent,
                            onTap: () => _confirmLogout(context, ref),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AppVersionText extends StatelessWidget {
  const _AppVersionText();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final packageInfo = snapshot.data;

        final versionText = packageInfo == null
            ? 'Version loading...'
            : 'Version ${packageInfo.version} (${packageInfo.buildNumber})';

        return Text(
          versionText,
          style: const TextStyle(
            color: ProfileScreen.textMuted,
            fontSize: 13,
            height: 1.35,
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 9),
        Text(
          isLoading ? '...' : title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ProfileScreen.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ProfileScreen.textMuted,
            fontSize: 11.5,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
