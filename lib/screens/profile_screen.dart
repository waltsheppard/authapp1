import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/credential_storage.dart';
import '../repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_state.dart';
import '../services/auth_service.dart';

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
  bool _loading = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _loadAttributes();
  }

  Future<void> _loadAttributes() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final attrs = await repo.fetchSession().then((_) => Amplify.Auth.fetchUserAttributes());
      for (final a in attrs) {
        if (a.userAttributeKey == CognitoUserAttributeKey.email) {
          _emailController.text = a.value;
        } else if (a.userAttributeKey == CognitoUserAttributeKey.phoneNumber) {
          _phoneController.text = a.value;
        } else if (a.userAttributeKey == CognitoUserAttributeKey.givenName) {
          _firstNameController.text = a.value;
        } else if (a.userAttributeKey == CognitoUserAttributeKey.familyName) {
          _lastNameController.text = a.value;
        } else if (a.userAttributeKey.key == 'custom:title') {
          _titleController.text = a.value;
        } else if (a.userAttributeKey.key == 'custom:organization') {
          _organizationController.text = a.value;
        }
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _updateEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await ref.read(authRepositoryProvider).updateEmail(email);
      if (res.nextStep.updateAttributeStep == 'CONFIRM_ATTRIBUTE_WITH_CODE') {
        _pendingAttributeKey = CognitoUserAttributeKey.email;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent via SMS.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated.')),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await ref.read(authRepositoryProvider).updatePhone(phone);
      if (res.nextStep.updateAttributeStep == 'CONFIRM_ATTRIBUTE_WITH_CODE') {
        _pendingAttributeKey = CognitoUserAttributeKey.phoneNumber;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent via Email.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone updated.')),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _pendingAttributeKey == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).confirmAttribute(key: _pendingAttributeKey!, code: code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attribute confirmed.')));
      _pendingAttributeKey = null;
      _codeController.clear();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendAttributeCode() async {
    if (_pendingAttributeKey == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resendAttributeCode(key: _pendingAttributeKey!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
      _startCooldown(30);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
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
    if (msg.contains('AliasExistsException')) return 'That email/phone is already in use.';
    if (msg.contains('TooManyRequestsException')) return 'Too many attempts. Please try again shortly.';
    if (msg.contains('CodeMismatchException')) return 'Incorrect verification code.';
    if (msg.contains('ExpiredCodeException')) return 'Verification code expired. Request a new one.';
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
    setState(() => _loading = true);
    try {
      await AuthService().updateProfileAttributes(
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        organization: _organizationController.text.trim().isEmpty ? null : _organizationController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _organizationController,
              decoration: const InputDecoration(
                labelText: 'Organization',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Organization is required' : null,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              child: const Text('Save profile'),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final r = RegExp(r'^.+@.+\..+$');
                if (!r.hasMatch(v.trim())) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _updateEmail,
              child: const Text('Update email'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (+E.164)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                final r = RegExp(r'^\+[1-9]\d{7,14}$');
                if (!r.hasMatch(v.trim())) return 'Enter phone in E.164 (e.g., +15551234567)';
                return null;
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _updatePhone,
              child: const Text('Update phone'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : _confirm,
              child: const Text('Confirm change'),
            ),
            TextButton(
              onPressed: _loading || _resendCooldown > 0 ? null : _resendAttributeCode,
              child: Text(_resendCooldown > 0 ? 'Resend code (${_resendCooldown}s)' : 'Resend code'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: _loading
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete account'),
                          content: const Text('This action is permanent. Are you sure?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      setState(() => _loading = true);
                      try {
                        await _authService.deleteUser();
                        // Clear any stored flags/tokens
                        await CredentialStorage().clear();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deleted')),
                        );
                        // Navigate back to login by popping to root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      } on AuthException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      } finally {
                        if (mounted) setState(() => _loading = false);
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


