import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthConfig {
  AuthConfig({
    RegExp? emailRegex,
    RegExp? phoneRegex,
    this.passwordMinLength = 8,
    this.rememberMeDefault = true,
  })  : emailRegex = emailRegex ?? RegExp(r'^.+@.+\..+$'),
        phoneRegex = phoneRegex ?? RegExp(r'^\+[1-9]\d{7,14}$');

  final RegExp emailRegex;
  final RegExp phoneRegex;
  final int passwordMinLength;
  final bool rememberMeDefault;
}

final authConfigProvider = Provider<AuthConfig>((ref) => AuthConfig());
