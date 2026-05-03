import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../data/services/sadhana_service.dart';

final sadhanaApiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final sadhanaServiceProvider = Provider<SadhanaService>((ref) {
  final apiService = ref.watch(sadhanaApiServiceProvider);
  return SadhanaService(apiService);
});
