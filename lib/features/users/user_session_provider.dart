import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String role;
  final String? token;

  AppUser({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    this.token,
  });

  bool get isLeader {
    return role == 'SERVANT_LEADER' ||
        role == 'SECTOR_LEADER' ||
        role == 'CIRCLE_LEADER' ||
        role == 'SUPER_ADMIN';
  }
}

class SelectedUserNotifier extends StateNotifier<AppUser?> {
  SelectedUserNotifier() : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString('user_id');
    final fullName = prefs.getString('user_full_name');
    final email = prefs.getString('user_email');
    final phone = prefs.getString('user_phone');
    final role = prefs.getString('user_role');
    final token = prefs.getString('auth_token');

    final hasBasicUser = id != null && fullName != null && role != null;
    final hasValidToken = token != null && token.trim().isNotEmpty;

    if (!hasBasicUser || !hasValidToken) {
      await prefs.remove('user_id');
      await prefs.remove('user_full_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_role');
      await prefs.remove('auth_token');

      state = null;
      return;
    }

    state = AppUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      token: token,
    );
  }

  Future<void> setUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', user.id);
    await prefs.setString('user_full_name', user.fullName);
    await prefs.setString('user_role', user.role);

    if (user.email != null) {
      await prefs.setString('user_email', user.email!);
    } else {
      await prefs.remove('user_email');
    }

    if (user.phone != null) {
      await prefs.setString('user_phone', user.phone!);
    } else {
      await prefs.remove('user_phone');
    }

    if (user.token != null && user.token!.isNotEmpty) {
      await prefs.setString('auth_token', user.token!);
    } else {
      await prefs.remove('auth_token');
    }

    state = user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_id');
    await prefs.remove('user_full_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    await prefs.remove('auth_token');

    state = null;
  }
}

final selectedUserProvider =
    StateNotifierProvider<SelectedUserNotifier, AppUser?>(
      (ref) => SelectedUserNotifier(),
    );
