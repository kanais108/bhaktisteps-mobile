import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'users_provider.dart';

class UserRegistrationScreen extends ConsumerStatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  ConsumerState<UserRegistrationScreen> createState() =>
      _UserRegistrationScreenState();
}

class _UserRegistrationScreenState
    extends ConsumerState<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  bool isSubmitting = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> registerUser() async {
    _dismissKeyboard();

    if (!_formKey.currentState!.validate()) return;

    final registeredEmail = emailController.text.trim();

    setState(() {
      isSubmitting = true;
    });

    try {
      final service = ref.read(usersServiceProvider);

      await service.createUser(
        fullName: fullNameController.text.trim(),
        email: registeredEmail,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFE8F7EC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Account Created',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4A3728),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Bhakti Steps account has been created successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7A6756),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE08A1E).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Registered Email',
                        style: TextStyle(
                          color: Color(0xFF7A6756),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        registeredEmail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4A3728),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Please sign in using this email address. We will send a secure one-time login code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7A6756),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE08A1E),
                  foregroundColor: Colors.white,
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
                  'Continue to Login',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(registeredEmail);
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Registration failed';

      if (e.response?.statusCode == 409) {
        message = 'A user with this email already exists';
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

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE08A1E), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E9),
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFFF6F1E9),
        foregroundColor: const Color(0xFF4A3728),
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE08A1E), Color(0xFFC96A12)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Register for Bhakti Steps',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A3728),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your devotee profile to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF7A6756)),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: fullNameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: inputDecoration(
                      'Full Name',
                      Icons.badge_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onEditingComplete: _dismissKeyboard,
                    onFieldSubmitted: (_) => _dismissKeyboard(),
                    decoration: inputDecoration(
                      'Email Address',
                      Icons.email_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }

                      final email = value.trim();
                      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

                      if (!emailRegex.hasMatch(email)) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE08A1E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isSubmitting ? 'Creating...' : 'Create Account',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
