import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';

final selectedUserProvider = StateProvider<UserModel?>((ref) => null);
