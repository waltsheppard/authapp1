import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:authapp1/features/auth/domain/auth_repository.dart';
import 'package:authapp1/features/auth/infrastructure/auth_service.dart';

class AmplifyAuthRepository implements AuthRepository, ProfileRepository {
  AmplifyAuthRepository(this._service);

  final AuthService _service;

  @override
  Future<void> configure() => _service.configureIfNeeded();

  @override
  Future<SignInResult> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  @override
  Future<SignInResult> confirmSignIn(String value) => _service.confirmSignIn(value);

  @override
  Future<SignUpResult> signUp({required String email, required String password, required String phone}) =>
      _service.signUp(email: email, password: password, phoneNumber: phone);

  @override
  Future<SignUpResult> confirmSignUp({required String email, required String code}) =>
      _service.confirmSignUp(email: email, code: code);

  @override
  Future<ResetPasswordResult> requestPasswordReset(String username) =>
      _service.requestPasswordReset(username);

  @override
  Future<ResendSignUpCodeResult> resendSignUpCode(String username) =>
      _service.resendSignUpCode(username);

  @override
  Future<CognitoAuthSession> fetchSession() => _service.fetchSession();

  @override
  Future<void> signOut() => _service.signOut();

  @override
  Future<void> deleteUser() => _service.deleteUser();

  @override
  Future<List<AuthUserAttribute>> fetchAttributes() => _service.fetchUserAttributes();

  @override
  Future<List<AuthUserAttribute>> updateProfileAttributes({
    String? title,
    String? firstName,
    String? lastName,
    String? organization,
  }) =>
      _service.updateProfileAttributes(
        title: title,
        firstName: firstName,
        lastName: lastName,
        organization: organization,
      );

  @override
  Future<UpdateUserAttributeResult> updateEmail(String email) => _service.updateEmail(email);

  @override
  Future<UpdateUserAttributeResult> updatePhone(String phone) => _service.updatePhone(phone);

  @override
  Future<void> confirmAttribute({required CognitoUserAttributeKey key, required String code}) =>
      _service.confirmAttribute(key: key, code: code);

  @override
  Future<SendUserAttributeVerificationCodeResult> resendAttributeCode({required CognitoUserAttributeKey key}) =>
      _service.resendAttributeCode(key: key);
}
