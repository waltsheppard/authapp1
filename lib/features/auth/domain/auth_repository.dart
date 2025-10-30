import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

abstract class AuthRepository {
  Future<void> configure();
  Future<SignInResult> signIn({required String email, required String password});
  Future<SignInResult> confirmSignIn(String value);
  Future<SignUpResult> signUp({required String email, required String password, required String phone});
  Future<SignUpResult> confirmSignUp({required String email, required String code});
  Future<ResetPasswordResult> requestPasswordReset(String username);
  Future<ResendSignUpCodeResult> resendSignUpCode(String username);
  Future<CognitoAuthSession> fetchSession();
  Future<void> signOut();
  Future<void> deleteUser();
}

abstract class ProfileRepository {
  Future<List<AuthUserAttribute>> fetchAttributes();
  Future<List<AuthUserAttribute>> updateProfileAttributes({
    String? title,
    String? firstName,
    String? lastName,
    String? organization,
  });
  Future<UpdateUserAttributeResult> updateEmail(String email);
  Future<UpdateUserAttributeResult> updatePhone(String phone);
  Future<void> confirmAttribute({required CognitoUserAttributeKey key, required String code});
  Future<SendUserAttributeVerificationCodeResult> resendAttributeCode({required CognitoUserAttributeKey key});
}
