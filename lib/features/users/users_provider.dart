import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/users_service.dart';

final usersServiceProvider = Provider<UsersService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return UsersService(apiService);
});

final usersProvider = FutureProvider<List<UserModel>>((ref) async {
  final service = ref.read(usersServiceProvider);
  return service.getUsers();
});
