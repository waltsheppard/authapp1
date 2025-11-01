import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:authapp1/features/auth/auth.dart';

class PinValidationException implements Exception {
  const PinValidationException(this.message);

  final String message;

  @override
  String toString() => 'PinValidationException: $message';
}

class SessionManager {
  SessionManager(this._ref);

  final Ref _ref;

  AuthRepository get _authRepository => _ref.read(authRepositoryProvider);
  CredentialStorage get _storage => _ref.read(credentialStorageProvider);
  AuthConfig get _config => _ref.read(authConfigProvider);

  Future<bool> hasPin() => _storage.hasPin();

  Future<void> updatePin({
    String? currentPin,
    required String newPin,
  }) async {
    final hasExisting = await hasPin();
    if (hasExisting) {
      if (currentPin == null || currentPin.isEmpty) {
        throw const PinValidationException('Current PIN required');
      }
      final valid = await _storage.verifyPin(currentPin);
      if (!valid) {
        throw const PinValidationException('Current PIN is incorrect');
      }
    }
    await _storage.savePin(newPin);
  }

  Future<bool> verifyPin(String pin) => _storage.verifyPin(pin);

  Future<void> clearPin() => _storage.clearPin();

  Future<bool> isRememberMeEnabled() async {
    final stored = await _storage.readRememberMe();
    return stored ?? _config.rememberMeDefault;
  }

  Future<void> updateRememberMe(bool remember, {String? email}) async {
    await _storage.saveRememberMe(remember);
    if (remember) {
      if (email != null && email.isNotEmpty) {
        await _storage.saveEmail(email);
      }
    } else {
      await _storage.clear();
      await _storage.saveRememberMe(false);
    }
  }

  Future<void> handleSuccessfulSignIn({
    required String email,
    required bool rememberMe,
  }) async {
    if (rememberMe) {
      await _storage.saveRememberMe(true);
      await _storage.saveEmail(email);
      final session = await currentSession();
      final refreshToken = session.userPoolTokensResult.valueOrNull?.refreshToken;
      if (refreshToken != null) {
        await _storage.saveRefreshToken(refreshToken);
      }
    } else {
      await updateRememberMe(false);
    }
  }

  Future<bool> canUseQuickSignIn() async {
    final remember = await isRememberMeEnabled();
    if (!remember) return false;
    final storedRefresh = await _storage.readRefreshToken();
    return storedRefresh != null && storedRefresh.isNotEmpty;
  }

  Future<String?> savedEmail() => _storage.readEmail();

  Future<bool> hasSavedCredentials() async {
    final email = await savedEmail();
    final refresh = await _storage.readRefreshToken();
    return email != null && email.isNotEmpty && refresh != null && refresh.isNotEmpty;
  }

  Future<CognitoAuthSession> currentSession() async {
    await _authRepository.configure();
    return _authRepository.fetchSession();
  }

  Future<void> signOut() async {
    final remember = await isRememberMeEnabled();
    final email = remember ? await savedEmail() : null;
    await _authRepository.signOut();
    await _storage.clear();
    if (remember) {
      await updateRememberMe(true, email: email);
    } else {
      await _storage.saveRememberMe(false);
    }
    await _ref.read(platformHooksProvider).onSignOut(_ref);
  }

  Future<void> clearStoredCredentials() async {
    final remember = await isRememberMeEnabled();
    await _storage.clear();
    await _storage.saveRememberMe(remember);
  }
}

final sessionManagerProvider = Provider<SessionManager>((ref) => SessionManager(ref));
