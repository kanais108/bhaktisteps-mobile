import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'users_provider.dart';
import 'user_session_provider.dart';

class UserSelectorScreen extends ConsumerWidget {
  const UserSelectorScreen({super.key});

  static const Color cream = Color(0xFFF6F1E9);
  static const Color textDark = Color(0xFF4A3728);
  static const Color textMuted = Color(0xFF7A6756);
  static const Color saffron = Color(0xFFE08A1E);
  static const Color deepSaffron = Color(0xFFC96A12);
  static const Color white = Colors.white;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/prabhupada_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
              child: Container(color: Colors.transparent),
            ),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cream.withValues(alpha: 0.72),
                    cream.withValues(alpha: 0.88),
                    cream.withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.10)),
          ),

          SafeArea(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: deepSaffron),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Text(
                      'Could not load users\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: textMuted, height: 1.5),
                    ),
                  ),
                ),
              ),
              data: (users) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                            decoration: BoxDecoration(
                              color: white.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Image.asset(
                                    'assets/images/bs_logo.png',
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Welcome to Bhakti Steps',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Select your devotee profile to continue your spiritual journey with steadiness, remembrance, and daily practice.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                16,
                                14,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: white.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Available Profiles',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: textDark,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Choose the profile you want to enter with',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: users.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No devotee profiles found',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 15,
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            padding: EdgeInsets.zero,
                                            itemCount: users.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (context, index) {
                                              final user = users[index];

                                              return Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  onTap: () {
                                                    ref
                                                            .read(
                                                              selectedUserProvider
                                                                  .notifier,
                                                            )
                                                            .state =
                                                        user;
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Ink(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFFFFFBF5),
                                                              Colors.white,
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                      border: Border.all(
                                                        color: saffron
                                                            .withValues(
                                                              alpha: 0.10,
                                                            ),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: saffron
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          blurRadius: 14,
                                                          offset: const Offset(
                                                            0,
                                                            6,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 58,
                                                          height: 58,
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                const LinearGradient(
                                                                  colors: [
                                                                    saffron,
                                                                    deepSaffron,
                                                                  ],
                                                                  begin: Alignment
                                                                      .topLeft,
                                                                  end: Alignment
                                                                      .bottomRight,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  18,
                                                                ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: saffron
                                                                    .withValues(
                                                                      alpha:
                                                                          0.20,
                                                                    ),
                                                                blurRadius: 14,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      7,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              user
                                                                      .fullName
                                                                      .isNotEmpty
                                                                  ? user.fullName[0]
                                                                        .toUpperCase()
                                                                  : '?',
                                                              style: const TextStyle(
                                                                color: white,
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 14,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                user.fullName,
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      textDark,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                user.phone,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color:
                                                                      textMuted,
                                                                ),
                                                              ),
                                                              if (user.email !=
                                                                  null) ...[
                                                                const SizedBox(
                                                                  height: 2,
                                                                ),
                                                                Text(
                                                                  user.email!,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        12.5,
                                                                    color:
                                                                        textMuted,
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 38,
                                                          height: 38,
                                                          decoration: BoxDecoration(
                                                            color: saffron
                                                                .withValues(
                                                                  alpha: 0.10,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: const Icon(
                                                            Icons
                                                                .arrow_forward_rounded,
                                                            size: 18,
                                                            color: deepSaffron,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
