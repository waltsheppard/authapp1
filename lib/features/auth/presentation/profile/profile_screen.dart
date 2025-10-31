import 'dart:async';

import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:authapp1/features/auth/auth.dart';
import 'package:authapp1/theme/app_theme.dart';
import 'package:authapp1/theme/layout/auth_layout.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _organizationController = TextEditingController();

  CognitoUserAttributeKey? _pendingAttributeKey;
  late final SessionManager _sessionManager;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _sessionManager = ref.read(sessionManagerProvider);
    _loadAttributes();
  }

  Future<void> _loadAttributes() async {
    try {
      await ref.read(profileControllerProvider.notifier).loadAttributes();
    } catch (_) {}
  }

  void _applyAttributes(List<AuthUserAttribute> attrs) {
    for (final attribute in attrs) {
      final value = attribute.value;
      if (attribute.userAttributeKey == CognitoUserAttributeKey.email) {
        if (_emailController.text != value) {
          _emailController.text = value;
        }
      } else if (attribute.userAttributeKey ==
          CognitoUserAttributeKey.phoneNumber) {
        if (_phoneController.text != value) {
          _phoneController.text = value;
        }
      } else if (attribute.userAttributeKey ==
          CognitoUserAttributeKey.givenName) {
        if (_firstNameController.text != value) {
          _firstNameController.text = value;
        }
      } else if (attribute.userAttributeKey ==
          CognitoUserAttributeKey.familyName) {
        if (_lastNameController.text != value) {
          _lastNameController.text = value;
        }
      } else if (attribute.userAttributeKey.key == 'custom:title') {
        if (_titleController.text != value) {
          _titleController.text = value;
        }
      } else if (attribute.userAttributeKey.key == 'custom:organization') {
        if (_organizationController.text != value) {
          _organizationController.text = value;
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final controller = ref.read(profileControllerProvider.notifier);
    try {
      final res = await controller.updateEmail(email);
      if (res.nextStep.updateAttributeStep ==
          AuthUpdateAttributeStep.confirmAttributeWithCode) {
        _pendingAttributeKey = CognitoUserAttributeKey.email;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent via SMS.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Email updated.')));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _updatePhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    final controller = ref.read(profileControllerProvider.notifier);
    try {
      final res = await controller.updatePhone(phone);
      if (res.nextStep.updateAttributeStep ==
          AuthUpdateAttributeStep.confirmAttributeWithCode) {
        _pendingAttributeKey = CognitoUserAttributeKey.phoneNumber;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent via Email.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Phone updated.')));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _pendingAttributeKey == null) return;
    final controller = ref.read(profileControllerProvider.notifier);
    try {
      await controller.confirmAttribute(key: _pendingAttributeKey!, code: code);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attribute confirmed.')));
      _pendingAttributeKey = null;
      _codeController.clear();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _resendAttributeCode() async {
    if (_pendingAttributeKey == null) return;
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .resendAttributeCode(_pendingAttributeKey!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
      _startCooldown(30);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  String _friendlyError(AuthException e) {
    final msg = e.message;
    if (msg.contains('AliasExistsException')) {
      return 'That email/phone is already in use.';
    }
    if (msg.contains('TooManyRequestsException')) {
      return 'Too many attempts. Please try again shortly.';
    }
    if (msg.contains('CodeMismatchException')) {
      return 'Incorrect verification code.';
    }
    if (msg.contains('ExpiredCodeException')) {
      return 'Verification code expired. Request a new one.';
    }
    return msg;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _titleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(profileControllerProvider.notifier);
    try {
      await controller.updateProfile(
        title:
            _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
        firstName:
            _firstNameController.text.trim().isEmpty
                ? null
                : _firstNameController.text.trim(),
        lastName:
            _lastNameController.text.trim().isEmpty
                ? null
                : _lastNameController.text.trim(),
        organization:
            _organizationController.text.trim().isEmpty
                ? null
                : _organizationController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<AuthUserAttribute>>>(
      profileControllerProvider,
      (previous, next) => next.whenData(_applyAttributes),
    );
    final profileState = ref.watch(profileControllerProvider);
    final isBusy = profileState.isLoading;
    final config = ref.watch(authConfigProvider);
    return AuthScaffold(
      title: 'Profile settings',
      maxContentWidth: 560,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isBusy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (profileState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'We couldn\'t refresh your profile. Try again shortly.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First name',
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'First name is required'
                          : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last name',
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Last name is required'
                          : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _organizationController,
              decoration: const InputDecoration(
                labelText: 'Organization',
                border: OutlineInputBorder(),
              ),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Organization is required'
                          : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: isBusy ? null : _saveProfile,
              child: const Text('Save profile'),
            ),
            const Divider(height: AppSpacing.xl),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!config.emailRegex.hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: isBusy ? null : _updateEmail,
              child: const Text('Update email'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (+E.164)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                if (!config.phoneRegex.hasMatch(v.trim())) {
                  return 'Enter phone in E.164 (e.g., +15551234567)';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: isBusy ? null : _updatePhone,
              child: const Text('Update phone'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: isBusy ? null : _confirm,
              child: const Text('Confirm change'),
            ),
            TextButton(
              onPressed:
                  isBusy || _resendCooldown > 0 ? null : _resendAttributeCode,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend code (${_resendCooldown}s)'
                    : 'Resend code',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  isBusy
                      ? null
                      : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Delete account'),
                                content: const Text(
                                  'This action is permanent. Are you sure?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );
                        if (confirmed != true) return;
                        if (!mounted) return;
                        try {
                          await ref
                              .read(profileControllerProvider.notifier)
                              .deleteAccount();
                          await _sessionManager.clearStoredCredentials();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Account deleted')),
                          );
                          navigator.popUntil((route) => route.isFirst);
                        } on AuthException catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
              child: const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
  }
}
