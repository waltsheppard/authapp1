import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:authapp1/features/auth/auth.dart';

class SignupController extends StateNotifier<AsyncValue<void>> {
  SignupController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String phone,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.configure();
      final result = await repo.signUp(email: email, password: password, phone: phone);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<SignUpResult> confirmSignUp({required String email, required String code}) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      final result = await repo.confirmSignUp(email: email, code: code);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<ResendSignUpCodeResult> resendCode(String email) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.configure();
      final result = await repo.resendSignUpCode(email);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final signupControllerProvider =
    StateNotifierProvider<SignupController, AsyncValue<void>>((ref) => SignupController(ref));
