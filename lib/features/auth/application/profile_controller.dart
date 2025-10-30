import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:authapp1/features/auth/auth.dart';

class ProfileController extends StateNotifier<AsyncValue<List<AuthUserAttribute>>> {
  ProfileController(this._ref) : super(const AsyncValue.data(<AuthUserAttribute>[]));

  final Ref _ref;

  Future<List<AuthUserAttribute>> loadAttributes() async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).configure();
      final attrs = await _ref.read(profileRepositoryProvider).fetchAttributes();
      state = AsyncData(attrs);
      return attrs;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<List<AuthUserAttribute>> updateProfile({
    String? title,
    String? firstName,
    String? lastName,
    String? organization,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(profileRepositoryProvider);
      final attrs = await repo.updateProfileAttributes(
        title: title,
        firstName: firstName,
        lastName: lastName,
        organization: organization,
      );
      state = AsyncData(attrs);
      return attrs;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UpdateUserAttributeResult> updateEmail(String email) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(profileRepositoryProvider);
      final result = await repo.updateEmail(email);
      state = AsyncData(await repo.fetchAttributes());
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UpdateUserAttributeResult> updatePhone(String phone) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(profileRepositoryProvider);
      final result = await repo.updatePhone(phone);
      state = AsyncData(await repo.fetchAttributes());
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> confirmAttribute({required CognitoUserAttributeKey key, required String code}) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(profileRepositoryProvider);
      await repo.confirmAttribute(key: key, code: code);
      state = AsyncData(await repo.fetchAttributes());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> resendAttributeCode(CognitoUserAttributeKey key) async {
    final repo = _ref.read(profileRepositoryProvider);
    await repo.resendAttributeCode(key: key);
  }

  Future<void> deleteAccount() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.deleteUser();
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<List<AuthUserAttribute>>>(
  (ref) => ProfileController(ref),
);
