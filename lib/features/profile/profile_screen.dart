import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sadhana/sadhana_history_screen.dart';
import '../users/user_selector_screen.dart';
import '../users/user_session_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color white = Colors.white;
  static const Color accent = Color(0xFFF59E0B);

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

  Color _roleBgColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return const Color(0xFFE0ECFF);
      case 'CIRCLE_LEADER':
        return const Color(0xFFE8F7EE);
      case 'SECTOR_LEADER':
        return const Color(0xFFFFF4E5);
      case 'SERVANT_LEADER':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _roleTextColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return const Color(0xFF1D4ED8);
      case 'CIRCLE_LEADER':
        return const Color(0xFF15803D);
      case 'SECTOR_LEADER':
        return const Color(0xFFB45309);
      case 'SERVANT_LEADER':
        return const Color(0xFF7E22CE);
      default:
        return textMuted;
    }
  }

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
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

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconBg = const Color(0xFFEFF6FF),
    Color iconColor = primary,
    Color? trailingColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: textMuted),
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
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
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 38,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _sectionCard(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 98,
                              height: 98,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [primary, primaryDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.22),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  selectedUser.fullName.isNotEmpty
                                      ? selectedUser.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile photo upload coming soon',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(16),
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
                        const SizedBox(height: 18),
                        Text(
                          selectedUser.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        if (selectedUser.phone != null &&
                            selectedUser.phone!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            selectedUser.phone!,
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        if (selectedUser.email != null &&
                            selectedUser.email!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            selectedUser.email!,
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _roleBgColor(selectedUser.role),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _roleLabel(selectedUser.role),
                            style: TextStyle(
                              color: _roleTextColor(selectedUser.role),
                              fontWeight: FontWeight.w700,
                            ),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage your journey, view your activity, and keep your profile up to date.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _actionTile(
                          icon: Icons.history_rounded,
                          title: 'Sadhana History',
                          subtitle: 'View your submitted daily entries',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SadhanaHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 16),
                        _actionTile(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          subtitle: 'Profile editing can be enabled next',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edit profile coming soon'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    child: Column(
                      children: [
                        _actionTile(
                          icon: Icons.logout_rounded,
                          title: 'Log Out',
                          subtitle: 'Sign out from this device',
                          iconBg: const Color(0xFFFFF1F2),
                          iconColor: Colors.redAccent,
                          trailingColor: Colors.redAccent,
                          onTap: () async {
                            await ref
                                .read(selectedUserProvider.notifier)
                                .logout();

                            if (!context.mounted) return;

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const UserSelectorScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
    );
  }
}
