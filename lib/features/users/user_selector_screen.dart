import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../navigation/app_router.dart';
import 'user_registration_screen.dart';
import 'user_session_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthService(api);
});

class UserSelectorScreen extends ConsumerStatefulWidget {
  const UserSelectorScreen({super.key});

  @override
  ConsumerState<UserSelectorScreen> createState() => _UserSelectorScreenState();
}

class _UserSelectorScreenState extends ConsumerState<UserSelectorScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  bool isSubmitting = false;
  bool otpSent = false;
  String? errorText;
  String requestedEmail = '';

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF2F6FED);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color white = Colors.white;
  static const Color accent = Color(0xFFF59E0B);

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> requestOtp() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => errorText = 'Please enter your email address');
      return;
    }

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.requestOtp(email);

      if (!mounted) return;

      setState(() {
        otpSent = true;
        requestedEmail = email;
        isSubmitting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent to your email')));
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Could not send OTP';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      setState(() {
        errorText = message;
        isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorText = 'Something went wrong';
        isSubmitting = false;
      });
    }
  }

  Future<void> verifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      setState(() => errorText = 'Please enter the OTP');
      return;
    }

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.verifyOtp(
        email: requestedEmail,
        otp: otp,
      );

      final appUser = AppUser(
        id: result.user.id,
        fullName: result.user.fullName,
        phone: result.user.phone,
        email: result.user.email,
        role: result.user.role,
        token: result.token,
      );

      await ref.read(selectedUserProvider.notifier).setUser(appUser);

      try {
        final notificationService = NotificationService(
          ref.read(apiServiceProvider),
        );

        await notificationService.initializeAndRegisterToken();

        if (mounted) {
          notificationService.listenToNotifications(context);
        }

        notificationService.handleNotificationTap(user: appUser);
        await notificationService.handleInitialNotification(user: appUser);
      } catch (e) {
        debugPrint('Push notification setup failed: $e');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(user: appUser)),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Invalid or expired OTP';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      setState(() {
        errorText = message;
        isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorText = 'Something went wrong';
        isSubmitting = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: textMuted,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.75)),
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
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => requestOtp(),
          decoration: _inputDecoration(
            label: 'Email Address',
            hint: 'Enter your email',
            icon: Icons.email_rounded,
          ),
        ),
        const SizedBox(height: 18),
        _primaryButton(
          text: 'Send OTP',
          onPressed: isSubmitting ? null : requestOtp,
          loading: isSubmitting,
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'We sent a 6-digit code to\n$requestedEmail',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => verifyOtp(),
          decoration: _inputDecoration(
            label: 'OTP',
            hint: 'Enter 6-digit code',
            icon: Icons.lock_outline_rounded,
          ),
        ),
        const SizedBox(height: 18),
        _primaryButton(
          text: 'Verify OTP',
          onPressed: isSubmitting ? null : verifyOtp,
          loading: isSubmitting,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isSubmitting
              ? null
              : () {
                  setState(() {
                    otpSent = false;
                    otpController.clear();
                    errorText = null;
                  });
                },
          child: const Text(
            'Use a different email',
            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      body: Stack(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                height: keyboardOpen
                    ? MediaQuery.of(context).size.height * 0.34
                    : MediaQuery.of(context).size.height * 0.56,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/prabhupada_bg.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.30),
                              Colors.black.withValues(alpha: 0.60),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!keyboardOpen)
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bhakti Steps',
                              style: TextStyle(
                                color: white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Recognize • Revitalize • Progress',
                                style: TextStyle(
                                  color: white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: keyboardOpen ? keyboardHeight : 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: keyboardOpen
                    ? MediaQuery.of(context).size.height * 0.62
                    : MediaQuery.of(context).size.height * 0.48,
              ),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
              decoration: const BoxDecoration(
                color: white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otpSent ? 'Verify your email' : 'Sign in with email',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        otpSent
                            ? 'Enter the OTP sent to continue your devotional progress.'
                            : 'Enter your registered email to receive a one-time login code.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: otpSent ? _otpStep() : _emailStep(),
                      ),
                      if (!otpSent) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const UserRegistrationScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'New here? Create an account',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
