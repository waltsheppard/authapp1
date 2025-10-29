import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/credential_storage.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../widgets/dialogs.dart';
import '../repositories/auth_repository.dart';
import '../state/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();
  final _credentialStorage = CredentialStorage();
  bool _loading = false;
  bool _biometricsAvailable = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.canCheckBiometrics();
    final remember = await _credentialStorage.readRememberMe();
    final savedEmail = await _credentialStorage.readEmail();
    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _rememberMe = remember;
        if (savedEmail != null) _emailController.text = savedEmail;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^.+@.+\..+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.configure();
      final res = await repo.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (res.isSignedIn && mounted) {
        await _postSignInSuccess();
        return;
      }
      // Handle challenges
      final step = res.nextStep.signInStep;
      if (step == AuthSignInStep.confirmSignInWithSmsMfaCode || step == AuthSignInStep.confirmSignInWithTotpMfaCode) {
        final code = await promptForInput(
          title: 'Enter verification code',
          label: 'Code',
          keyboard: TextInputType.number,
          context: context,
        );
        if (code == null || code.isEmpty) return;
        final conf = await repo.confirmSignIn(code);
        if (conf.isSignedIn && mounted) {
          await _postSignInSuccess();
        }
      } else if (step == AuthSignInStep.newPasswordRequired) {
        final newPassword = await promptForInput(
          title: 'Set new password',
          label: 'New password',
          obscure: true,
          context: context,
        );
        if (newPassword == null || newPassword.isEmpty) return;
        final conf = await repo.confirmSignIn(newPassword);
        if (conf.isSignedIn && mounted) {
          await _postSignInSuccess();
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postSignInSuccess() async {
    if (_rememberMe) {
      await _credentialStorage.saveRememberMe(true);
      await _credentialStorage.saveEmail(_emailController.text.trim());
      final session = await _authService.fetchSession();
      final refreshToken = session.userPoolTokensResult.valueOrNull?.refreshToken;
      if (refreshToken != null) {
        await _credentialStorage.saveRefreshToken(refreshToken);
      }
    } else {
      await _credentialStorage.clear();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<String?> _promptForInput({
    required String title,
    required String label,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: keyboard,
          obscureText: obscure,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _biometricLogin() async {
    final ok = await _biometricService.authenticate(
      reason: 'Authenticate to sign in',
    );
    if (!ok) return;
    final remember = await _credentialStorage.readRememberMe();
    if (!remember) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick sign-in disabled. Enable Remember me.')),
      );
      return;
    }
    // Try to refresh session using stored refresh token if available.
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.configure();
      final session = await repo.fetchSession();
      if (session.isSignedIn) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        return;
      }
      final storedRefresh = await _credentialStorage.readRefreshToken();
      final email = await _credentialStorage.readEmail();
      if (storedRefresh != null && email != null) {
        // Amplify Flutter does not expose a manual refresh call; it refreshes automatically
        // when making authorized calls. As a fallback, we can attempt a silent signIn
        // if using SRP requires password; otherwise prompt user.
        // Here we simply inform the user to sign in normally if session is expired.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please sign in once.')),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No session found. Sign in once to enable quick sign-in.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }
    try {
      await _authService.configureIfNeeded();
      await Amplify.Auth.resetPassword(username: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code sent to your email')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                StatefulBuilder(builder: (context, setLocal) {
                  bool obscure = true;
                  return TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setLocal(() => obscure = !obscure),
                    ),
                  ),
                  obscureText: obscure,
                  validator: _validatePassword,
                );
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _rememberMe = v);
                        await _credentialStorage.saveRememberMe(v);
                        if (!v) {
                          // If turning off remember, clear stored values
                          await _credentialStorage.clear();
                        }
                      },
                    ),
                    const Text('Remember me'),
                  ],
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 8),
                if (_biometricsAvailable)
                  OutlinedButton.icon(
                    onPressed: _biometricLogin,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use biometrics'),
                  ),
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


