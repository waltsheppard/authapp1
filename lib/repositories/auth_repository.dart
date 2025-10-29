import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;
  AuthRepository(this._service);

  Future<void> configure() => _service.configureIfNeeded();

  Future<SignInResult> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  Future<SignInResult> confirmSignIn(String value) => _service.confirmSignIn(value);

  Future<SignUpResult> signUp({required String email, required String password, required String phone}) =>
      _service.signUp(email: email, password: password, phoneNumber: phone);

  Future<SignUpResult> confirmSignUp({required String email, required String code}) =>
      _service.confirmSignUp(email: email, code: code);

  Future<ResetPasswordResult> requestPasswordReset(String username) => _service.requestPasswordReset(username);

  Future<CognitoAuthSession> fetchSession() => _service.fetchSession();

  Future<AuthUpdateAttributeResult> updateEmail(String email) => _service.updateEmail(email);
  Future<AuthUpdateAttributeResult> updatePhone(String phone) => _service.updatePhone(phone);
  Future<void> confirmAttribute({required CognitoUserAttributeKey key, required String code}) =>
      _service.confirmAttribute(key: key, code: code);

  Future<void> deleteUser() => _service.deleteUser();
}



