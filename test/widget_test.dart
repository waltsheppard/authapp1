// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:authapp1/config/app_environment.dart';
import 'package:authapp1/features/auth/auth.dart';
import 'package:authapp1/main.dart';
import 'package:authapp1/screens/splash_screen.dart';

class _FakeAuthRepository implements AuthRepository, ProfileRepository {
  const _FakeAuthRepository();

  @override
  Future<void> configure() async {}

  @override
  @override
  Future<CognitoAuthSession> fetchSession() async =>
      Future.error(const SignedOutException('User not signed in'));

  @override
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) => Future.error(UnimplementedError());

  @override
  Future<SignInResult> confirmSignIn(String value) =>
      Future.error(UnimplementedError());

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String phone,
    required String title,
    required String firstName,
    required String lastName,
    required String organization,
  }) => Future.error(UnimplementedError());

  @override
  Future<SignUpResult> confirmSignUp({
    required String email,
    required String code,
  }) => Future.error(UnimplementedError());

  @override
  Future<ResetPasswordResult> requestPasswordReset(String username) =>
      Future.error(UnimplementedError());

  @override
  Future<ResendSignUpCodeResult> resendSignUpCode(String username) =>
      Future.error(UnimplementedError());

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteUser() => Future.error(UnimplementedError());

  @override
  Future<List<AuthUserAttribute>> fetchAttributes() async => const [];

  @override
  Future<List<AuthUserAttribute>> updateProfileAttributes({
    String? title,
    String? firstName,
    String? lastName,
    String? organization,
  }) => Future.error(UnimplementedError());

  @override
  Future<UpdateUserAttributeResult> updateEmail(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<UpdateUserAttributeResult> updatePhone(String phone) =>
      Future.error(UnimplementedError());

  @override
  Future<void> confirmAttribute({
    required CognitoUserAttributeKey key,
    required String code,
  }) => Future.error(UnimplementedError());

  @override
  Future<SendUserAttributeVerificationCodeResult> resendAttributeCode({
    required CognitoUserAttributeKey key,
  }) => Future.error(UnimplementedError());
}

void main() {
  testWidgets('renders splash screen on launch', (WidgetTester tester) async {
    const fakeRepository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          profileRepositoryProvider.overrideWithValue(fakeRepository),
        ],
        child: const MyApp(environment: AppEnvironment.dev),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
