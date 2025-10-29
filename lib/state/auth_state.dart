import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthController extends StateNotifier<AsyncValue<AuthSession>> {
  AuthController() : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      state = AsyncData(session);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authProvider = StateNotifierProvider<AuthController, AsyncValue<AuthSession>>((ref) {
  final ctrl = AuthController();
  ctrl.load();
  return ctrl;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(AuthService());
});


