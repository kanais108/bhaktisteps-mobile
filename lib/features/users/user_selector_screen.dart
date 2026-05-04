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

class _UserSelectorScreenState extends ConsumerState<UserSelectorScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  late final AnimationController animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;

  bool isSubmitting = false;
  bool otpSent = false;
  String? errorText;
  String requestedEmail = '';

  static const Color background = Color(0xFFFFFBF4);
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color white = Colors.white;
  static const Color accent = Color(0xFFF59E0B);
  static const Color cream = Color(0xFFFFF7ED);

  static const String heroAsset = 'assets/images/prabhupada_bg.png';

  // Replace this path with your actual logo asset if different.
  static const String logoAsset = 'assets/images/bs_logo.png';

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login code sent to your email')),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Could not send login code';
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
      setState(() => errorText = 'Please enter the login code');
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

      String message = 'Invalid or expired login code';
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: const TextStyle(
        color: textMuted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.70)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primary.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: loading
              ? const SizedBox.shrink()
              : Icon(icon, color: white, size: 21),
          label: loading
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
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoBadge(bool compact) {
    final size = compact ? 86.0 : 116.0;
    final innerPadding = compact ? 14.0 : 18.0;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(innerPadding),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(compact ? 26 : 34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
      ),
      child: Image.asset(
        logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(compact ? 18 : 24),
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: white,
              size: 40,
            ),
          );
        },
      ),
    );
  }

  Widget _brandHero({
    required double height,
    required bool compact,
    required bool keyboardOpen,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              heroAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF082F5F).withValues(alpha: 0.82),
                    const Color(0xFF082F5F).withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.10),
                  ],
                ),
              ),
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
                    Colors.transparent,
                    const Color(0xFF082F5F).withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
          ),
          if (!keyboardOpen)
            Positioned(
              left: compact ? 24 : 60,
              top: compact ? 54 : 76,
              width: compact ? 260 : 360,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_florist_rounded,
                      color: accent,
                      size: compact ? 30 : 38,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bhakti\nSteps',
                      style: TextStyle(
                        color: white,
                        fontSize: compact ? 42 : 62,
                        fontWeight: FontWeight.w900,
                        height: 0.96,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Recognize • Revitalize • Progress',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A simple way to stay connected\nto your spiritual journey.',
                      style: TextStyle(
                        color: white.withValues(alpha: 0.92),
                        fontSize: compact ? 14 : 17,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ornamentBackground() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -60,
            bottom: 80,
            child: Icon(
              Icons.temple_hindu_rounded,
              size: 150,
              color: accent.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            right: -48,
            bottom: 110,
            child: Icon(
              Icons.temple_hindu_rounded,
              size: 160,
              color: accent.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            left: 34,
            bottom: 24,
            child: Icon(
              Icons.local_florist_rounded,
              size: 48,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            right: 38,
            bottom: 30,
            child: Icon(
              Icons.local_florist_rounded,
              size: 52,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      key: const ValueKey('email-step'),
      mainAxisSize: MainAxisSize.min,
      children: [
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
          text: 'Send Login Code',
          icon: Icons.send_rounded,
          onPressed: isSubmitting ? null : requestOtp,
          loading: isSubmitting,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: textMuted.withValues(alpha: 0.80),
              size: 17,
            ),
            const SizedBox(width: 7),
            const Flexible(
              child: Text(
                'We’ll send a secure one-time code to your registered email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      key: const ValueKey('otp-step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            'We sent a 6-digit code to\n$requestedEmail',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: textMuted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => verifyOtp(),
          decoration: _inputDecoration(
            label: 'Login Code',
            hint: 'Enter 6-digit code',
            icon: Icons.lock_outline_rounded,
          ),
        ),
        const SizedBox(height: 18),
        _primaryButton(
          text: 'Verify Login Code',
          icon: Icons.verified_rounded,
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
            style: TextStyle(color: primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _loginCard({required bool compact, required bool keyboardOpen}) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: compact ? double.infinity : 620,
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 22 : 34,
            compact ? 58 : 76,
            compact ? 22 : 34,
            compact ? 22 : 30,
          ),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(compact ? 30 : 36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!keyboardOpen) ...[
                const Icon(
                  Icons.local_florist_rounded,
                  color: accent,
                  size: 22,
                ),
                const SizedBox(height: 10),
                Text(
                  otpSent
                      ? 'Enter the code sent to your email.'
                      : 'Every step in devotion brings us closer\nto a life of peace, purpose, and grace.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: otpSent ? _otpStep() : _emailStep(),
              ),
              if (!otpSent) ...[
                const SizedBox(height: 18),
                Divider(color: textMuted.withValues(alpha: 0.16)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'New here? ',
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const UserRegistrationScreen(),
                                ),
                              );
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final keyboardHeight = media.viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;

    final shortestSide = size.shortestSide;
    final isTablet = shortestSide >= 700;
    final isSmallPhone = size.height < 700;

    final heroHeight = keyboardOpen
        ? size.height * (isTablet ? 0.34 : 0.30)
        : size.height *
              (isTablet
                  ? 0.52
                  : isSmallPhone
                  ? 0.42
                  : 0.48);

    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final cardTopOverlap = isTablet ? 88.0 : 70.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: background,
      body: Stack(
        children: [
          _brandHero(
            height: heroHeight,
            compact: !isTablet,
            keyboardOpen: keyboardOpen,
          ),
          Positioned.fill(
            top: heroHeight - cardTopOverlap,
            child: Container(
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
              ),
              child: _ornamentBackground(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                keyboardOpen ? 18 : heroHeight - cardTopOverlap,
                horizontalPadding,
                keyboardOpen ? keyboardHeight + 24 : 34,
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: isTablet ? 62 : 48),
                      child: _loginCard(
                        compact: !isTablet,
                        keyboardOpen: keyboardOpen,
                      ),
                    ),
                    if (!keyboardOpen) _logoBadge(!isTablet),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
