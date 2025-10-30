import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorage {
  static const _keyEmail = 'cred_email';
  static const _keyRefreshToken = 'cred_refresh_token';
  static const _keyRemember = 'cred_remember_me';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveRememberMe(bool remember) async {
    await _storage.write(key: _keyRemember, value: remember ? '1' : '0');
  }

  Future<bool?> readRememberMe() async {
    final v = await _storage.read(key: _keyRemember);
    if (v == null) return null;
    return v == '1';
  }

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
  }

  Future<String?> readEmail() async {
    return _storage.read(key: _keyEmail);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyRemember);
  }
}

