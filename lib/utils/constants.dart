import 'package:flutter/foundation.dart';

class AppConstants {
  static const int resendCooldownSeconds = 30;

  static final RegExp emailRegex = RegExp(r'^.+@.+\..+$');
  static final RegExp e164Regex = RegExp(r'^\+[1-9]\d{7,14}$');

  static bool get isWeb => kIsWeb;
}



