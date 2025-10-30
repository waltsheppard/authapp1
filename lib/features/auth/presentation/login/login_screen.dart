import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:authapp1/features/auth/auth.dart';
import 'package:authapp1/screens/home_screen.dart';
import 'package:authapp1/widgets/dialogs.dart';
import 'package:authapp1/theme/app_theme.dart';
import 'package:authapp1/theme/layout/auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final BiometricService _biometricService;
  late final SessionManager _sessionManager;
  bool _biometricsAvailable = false;
  late bool _rememberMe;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _biometricService = ref.read(biometricServiceProvider);
    _sessionManager = ref.read(sessionManagerProvider);
    _rememberMe = ref.read(authConfigProvider).rememberMeDefault;
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
    final remember = await _sessionManager.isRememberMeEnabled();
    final savedEmail = await _sessionManager.savedEmail();
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
    final regex = ref.read(authConfigProvider).emailRegex;
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    final minLength = ref.read(authConfigProvider).passwordMinLength;
    if (value.length < minLength) return 'Minimum $minLength characters';
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(loginControllerProvider.notifier);
    try {
      final res = await controller.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (res.isSignedIn) {
        await _postSignInSuccess();
        return;
      }
      // Handle challenges
      final step = res.nextStep.signInStep;
      if (step == AuthSignInStep.confirmSignInWithSmsMfaCode || step == AuthSignInStep.confirmSignInWithTotpMfaCode) {
        if (!mounted) return;
        final code = await promptForInput(
          title: 'Enter verification code',
          label: 'Code',
          keyboard: TextInputType.number,
          context: context,
        );
        if (code == null || code.isEmpty) return;
        final conf = await controller.confirmSignIn(code);
        if (conf.isSignedIn && mounted) {
          await _postSignInSuccess();
        }
      } else if (step == AuthSignInStep.confirmSignInWithNewPassword) {
        if (!mounted) return;
        final newPassword = await promptForInput(
          title: 'Set new password',
          label: 'New password',
          obscure: true,
          context: context,
        );
        if (newPassword == null || newPassword.isEmpty) return;
        final conf = await controller.confirmSignIn(newPassword);
        if (conf.isSignedIn && mounted) {
          await _postSignInSuccess();
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _postSignInSuccess() async {
    await _sessionManager.handleSuccessfulSignIn(
      email: _emailController.text.trim(),
      rememberMe: _rememberMe,
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _biometricLogin() async {
    final ok = await _biometricService.authenticate(
      reason: 'Authenticate to sign in',
    );
    if (!ok) return;
    final allowQuickSignIn = await _sessionManager.canUseQuickSignIn();
    if (!allowQuickSignIn) {
      final rememberEnabled = await _sessionManager.isRememberMeEnabled();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rememberEnabled
                ? 'Quick sign-in not available yet. Sign in once to enable it.'
                : 'Quick sign-in disabled. Enable Remember me.',
          ),
        ),
      );
      return;
    }
    // Try to refresh session using stored refresh token if available.
    try {
      final session = await _sessionManager.currentSession();
      if (session.isSignedIn) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        return;
      }
      final hasStored = await _sessionManager.hasSavedCredentials();
      if (hasStored) {
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
      final controller = ref.read(loginControllerProvider.notifier);
      await controller.requestPasswordReset(email);
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
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;
    return AuthScaffold(
      title: 'Login',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (loginState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  loginState.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
            SizedBox(height: AppSpacing.sm * 1.5),
            TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Checkbox(
                      value: _rememberMe,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _rememberMe = v);
                        await _sessionManager.updateRememberMe(
                          v,
                          email: v ? _emailController.text.trim() : null,
                        );
                      },
                ),
                const Text('Remember me'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
                  onPressed: isLoading ? null : _signIn,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
            const SizedBox(height: AppSpacing.sm),
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
    );
  }
}
