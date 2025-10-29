import 'package:flutter_test/flutter_test.dart';
import 'package:authapp1/repositories/auth_repository.dart';
import 'package:authapp1/services/auth_service.dart';

class _FakeAuthService extends AuthService {}

void main() {
  test('AuthRepository constructs with service', () {
    final repo = AuthRepository(_FakeAuthService());
    expect(repo, isNotNull);
  });
}



