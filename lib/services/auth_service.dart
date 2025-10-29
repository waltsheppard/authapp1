import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  Future<void> configureIfNeeded() async {
    if (!Amplify.isConfigured) {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugins([auth]);
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    final userAttributes = {
      CognitoUserAttributeKey.email: email,
      CognitoUserAttributeKey.phoneNumber: phoneNumber,
    };
    return await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(userAttributes: userAttributes),
    );
  }

  Future<SignUpResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    return await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
  }

  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    return await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
  }

  Future<CognitoAuthSession> fetchSession() async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session;
  }

  Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  Future<ResetPasswordResult> resetPassword({
    required String email,
  }) async {
    return await Amplify.Auth.resetPassword(username: email);
  }

  Future<UpdatePasswordResult> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    return await Amplify.Auth.confirmResetPassword(
      username: email,
      newPassword: newPassword,
      confirmationCode: confirmationCode,
    );
  }

  Future<AuthUpdateAttributeResult> updateEmail(String email) async {
    return Amplify.Auth.updateUserAttribute(
      userAttributeKey: CognitoUserAttributeKey.email,
      value: email,
    );
  }

  Future<AuthUpdateAttributeResult> updatePhone(String phoneNumber) async {
    return Amplify.Auth.updateUserAttribute(
      userAttributeKey: CognitoUserAttributeKey.phoneNumber,
      value: phoneNumber,
    );
  }

  Future<void> confirmAttribute({
    required CognitoUserAttributeKey key,
    required String code,
  }) async {
    await Amplify.Auth.confirmUserAttribute(
      userAttributeKey: key,
      confirmationCode: code,
    );
  }

  Future<void> deleteUser() async {
    await Amplify.Auth.deleteUser();
  }

  Future<List<AuthUserAttribute>> fetchUserAttributes() async {
    return Amplify.Auth.fetchUserAttributes();
  }

  Future<List<AuthUserAttribute>> updateProfileAttributes({
    String? title,
    String? firstName,
    String? lastName,
    String? organization,
  }) async {
    final List<AuthUserAttribute> attrs = [];
    if (firstName != null) {
      attrs.add(AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.givenName, value: firstName));
    }
    if (lastName != null) {
      attrs.add(AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.familyName, value: lastName));
    }
    if (title != null) {
      attrs.add(AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.custom('title'), value: title));
    }
    if (organization != null) {
      attrs.add(AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.custom('organization'), value: organization));
    }
    if (attrs.isEmpty) return fetchUserAttributes();
    final results = await Amplify.Auth.updateUserAttributes(attributes: attrs);
    // Return refreshed attributes after update
    return fetchUserAttributes();
  }

  Future<SignInResult> confirmSignIn(String confirmationValue) async {
    return Amplify.Auth.confirmSignIn(confirmationValue: confirmationValue);
  }

  Future<ResetPasswordResult> requestPasswordReset(String username) async {
    return Amplify.Auth.resetPassword(username: username);
  }

  Future<ResendSignUpCodeResult> resendSignUpCode(String username) async {
    return Amplify.Auth.resendSignUpCode(username: username);
  }

  Future<ResendUserAttributeConfirmationCodeResult> resendAttributeCode(
      {required CognitoUserAttributeKey key}) async {
    return Amplify.Auth
        .resendUserAttributeConfirmationCode(userAttributeKey: key);
  }
}


